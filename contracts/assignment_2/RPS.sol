//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../BaseAssignment.sol";

contract RPS is BaseAssignment {
    enum GameState {
        Waiting,
        Starting,
        Playing,
        Revealing
    }
    enum Choice {
        None,
        Rock,
        Paper,
        Scissors
    }
    enum Action {
        Start,
        Play,
        Reveal
    }
    mapping(string => Choice) private stringToChoice;
    mapping(GameState => string) private gameStateToString;
    mapping(string => Action) private stringToAction;
    GameState private state = GameState.Waiting;
    uint256 private gameCounter = 0;
    address private player1;
    address private player2;
    bytes32 private player1choicehashed;
    bytes32 private player2choicehashed;
    Choice private player1choice;
    Choice private player2choice;
    bool public player1choicehashSubmitted;
    bool public player2choicehashSubmitted;
    bool private player1choiceSubmitted;
    bool private player2choiceSubmitted;
    uint private fee = 0.001 ether;
    uint256 private maxStartBlock = 10;
    uint256 private maxPlayBlock = 10;
    uint256 private maxRevealBlock = 10;
    uint private currActionBlockNumber;

    constructor(address _validator) BaseAssignment(0xbb94CBc84004548b9e174955bB4e26a1757cc5C3)  {

    stringToChoice["none"] = Choice.None;
    stringToChoice["rock"] = Choice.Rock;
    stringToChoice["paper"] = Choice.Paper;
    stringToChoice["scissors"] = Choice.Scissors;
    gameStateToString[GameState.Waiting] = "waiting";
    gameStateToString[GameState.Starting] = "starting";
    gameStateToString[GameState.Playing] = "playing";
    gameStateToString[GameState.Revealing] = "revealing";
    stringToAction["start"] = Action.Start;
    stringToAction["play"] = Action.Play;
    stringToAction["reveal"] = Action.Reveal;

    }
    // event to indicate that the game has started with player 1
    event Started(uint256 gameCounter, address player1);

    // event to indicate that the game is now being played with both players
    event Playing(uint256 gameCounter, address player1, address player2);

    // event to indicate that the game has ended with a winner or a draw
    event Ended(uint256 gameCounter, address winner, int8 outcomeCode);

    function getState() public view returns (string memory) {
        return gameStateToString[state];
    }

    function getGameCounter() public view returns (uint256) {
        return gameCounter;
    }

    function start() public payable returns (uint256) {
        require(
            state == GameState.Waiting || state == GameState.Starting,
            "Other game is into play, Please wait before you can start a new game!"
        );
        require(
            msg.value >= fee,
            "Please pay enough amount of 0.001 ether to participate"
        );
        if (state == GameState.Waiting) {
            player1 = msg.sender;
            state = GameState.Starting;
            gameCounter += 1;
            currActionBlockNumber = getBlockNumber();
            emit Started(gameCounter, player1);
            return 1;
        }
        if (state == GameState.Starting) {
            if (checkMaxTime() == false) {
                player1 = msg.sender;
                state = GameState.Starting;
                gameCounter += 1;
                currActionBlockNumber = getBlockNumber();
                emit Started(gameCounter, player1);
                return 1;
            }
            player2 = msg.sender;
            state = GameState.Playing;
            currActionBlockNumber = getBlockNumber();
            emit Playing(gameCounter, player1, player2);
            return 2;
        }
    }

    function play(string memory choice) public returns (int256) {
        require(state == GameState.Playing, "The game is not in play mode");
        require(
            msg.sender == player1 || msg.sender == player2,
            "Only registered players can play the game"
        );
        require(
            stringToChoice[choice] == Choice.Rock ||
                stringToChoice[choice] == Choice.Paper ||
                stringToChoice[choice] == Choice.Scissors,
            "Please select valid choice"
        );
        require(
            checkMaxTime(),
            "Maximum Time for you to play the game has passed"
        );
        if (msg.sender == player1) {
            require(
                player1choiceSubmitted == false,
                "You can not submit your choice twice."
            );
            player1choice = stringToChoice[choice];
            player1choiceSubmitted = true;
        } else {
            require(
                player2choiceSubmitted == false,
                "You can not submit your choice twice."
            );
            player2choice = stringToChoice[choice];
            player2choiceSubmitted = true;
        }
        int256 returncode;
        if (player1choiceSubmitted && player2choiceSubmitted) {
            Choice winningChoice = solveGame(player1choice, player2choice);

            if (player1choice == winningChoice) {
                payable(player1).transfer(address(this).balance);
                emit Ended(gameCounter, player1, 1);
                returncode = 1;
            } else {
                if (player2choice == winningChoice) {
                    payable(player2).transfer(address(this).balance);
                    emit Ended(gameCounter, player2, 2);
                    returncode = 2;
                } else {
                    returncode = 0;
                    emit Ended(gameCounter, address(0), 0);
                }
            }
            resetplayerdata();
            state = GameState.Waiting;
            return returncode;
        } else {
            return -1;
        }
    }

    function setMaxTime(string memory action, uint256 maxTime) public {
        require(
            state == GameState.Waiting,
            "You can not set Max Time now, since Game is already initialised"
        );
        if (stringToAction[action] == Action.Start) {
            maxStartBlock = maxTime;
        } else if (stringToAction[action] == Action.Play) {
            maxPlayBlock = maxTime;
        } else if (stringToAction[action] == Action.Reveal) {
            maxRevealBlock = maxTime;
        } else {
            revert("Invalid action.");
        }
    }

    function checkMaxTime() private returns (bool) {
        if (
            state == GameState.Starting &&
            getBlockNumber() > currActionBlockNumber + maxStartBlock
        ) {
            payable(player1).transfer((address(this).balance) - msg.value);
            emit Ended(gameCounter, player1, -1);
            resetGame();
            return false;
        }
        if (
            state == GameState.Playing &&
            getBlockNumber() > currActionBlockNumber + maxPlayBlock
        ) {
            if (player1choiceSubmitted) {
                payable(player1).transfer(address(this).balance);
                emit Ended(gameCounter, player1, -1);
            }
            if (player2choiceSubmitted) {
                payable(player2).transfer(address(this).balance);
                emit Ended(gameCounter, player2, -1);
            }
            resetGame();
            return false;
        }
        if (
            state == GameState.Revealing &&
            getBlockNumber() > currActionBlockNumber + maxRevealBlock
        ) {
            if (player1choiceSubmitted) {
                payable(player1).transfer(address(this).balance);
                emit Ended(gameCounter, player1, -1);
            }
            if (player2choiceSubmitted) {
                payable(player2).transfer(address(this).balance);
                emit Ended(gameCounter, player2, -1);
            }
            resetGame();
            return false;
        }
        return true;
    }

    function solveGame(
        Choice player1Choice,
        Choice player2Choice
    ) private pure returns (Choice) {
        if (player1Choice == Choice.Rock && player2Choice == Choice.Paper) {
            return Choice.Paper;
        } else if (
            player1Choice == Choice.Rock && player2Choice == Choice.Scissors
        ) {
            return Choice.Rock;
        } else if (
            player1Choice == Choice.Paper && player2Choice == Choice.Rock
        ) {
            return Choice.Paper;
        } else if (
            player1Choice == Choice.Paper && player2Choice == Choice.Scissors
        ) {
            return Choice.Scissors;
        } else if (
            player1Choice == Choice.Scissors && player2Choice == Choice.Rock
        ) {
            return Choice.Rock;
        } else if (
            player1Choice == Choice.Scissors && player2Choice == Choice.Paper
        ) {
            return Choice.Scissors;
        } else {
            return Choice.None;
        }
    }

    function resetplayerdata() private {
        player1 = address(0);
        player2 = address(0);
        player1choice = Choice.None;
        player2choice = Choice.None;
        player1choiceSubmitted = false;
        player2choiceSubmitted = false;
        player1choicehashSubmitted = false;
        player2choicehashSubmitted = false;
        player1choicehashed = bytes32(0);
        player2choicehashed = bytes32(0);
    }

    function resetGame() private {
        resetplayerdata();
        state = GameState.Waiting;
    }

    function forceReset() public {
        require(
            isValidator(msg.sender),
            "Force Reset can only be called by Validator"
        );
        resetplayerdata();
        state = GameState.Waiting;
    }

    function playPrivate(bytes32 hashedChoice) public returns (int256) {
        require(state == GameState.Playing, "The game is not in play mode");
        require(
            msg.sender == player1 || msg.sender == player2,
            "Only registered players can play the game"
        );
        require(
            checkMaxTime(),
            "Maximum Time for you to play the game has passed"
        );
        if (msg.sender == player1) {
            require(
                player1choicehashSubmitted == false,
                "You can not submit your choice twice."
            );
            player1choicehashed = hashedChoice;
            player1choicehashSubmitted = true;
        } else {
            require(
                player2choicehashSubmitted == false,
                "You can not submit your choice twice."
            );
            player2choicehashed = hashedChoice;
            player2choicehashSubmitted = true;
            state = GameState.Revealing;
            currActionBlockNumber = getBlockNumber();
        }
    }

    function reveal(
        string memory plainChoice,
        string memory seed
    ) public returns (int256) {
        require(
            msg.sender == player1 || msg.sender == player2,
            "Only registered players can call this function"
        );
        require(state == GameState.Revealing, "Game State is not revealing");
        // require(
        //     checkMaxTime(),
        //     "Maximum Time for you to play the game has passed"
        // );
        if (checkMaxTime() == false) {
            return -1;
        }
        bytes32 hashedChoice = keccak256(
            abi.encodePacked(string.concat(seed, "_", plainChoice))
        );
        if (msg.sender == player1) {
            require(
                player1choiceSubmitted == false,
                "You can not reveal your choice twice."
            );
            if (hashedChoice == player1choicehashed) {
                player1choice = stringToChoice[plainChoice];
                player1choiceSubmitted = true;
            }
        } else {
            require(
                player2choiceSubmitted == false,
                "You can not submit your choice twice."
            );
            if (hashedChoice == player2choicehashed) {
                player2choice = stringToChoice[plainChoice];
                player2choiceSubmitted = true;
            }
        }
        int256 returncode;
        if (player1choiceSubmitted && player2choiceSubmitted) {
            Choice winningChoice = solveGame(player1choice, player2choice);

            if (player1choice == winningChoice) {
                payable(player1).transfer(address(this).balance);
                returncode = 1;
            } else {
                if (player2choice == winningChoice) {
                    payable(player2).transfer(address(this).balance);
                    returncode = 2;
                } else {
                    returncode = 0;
                }
            }
            resetplayerdata();
            state = GameState.Waiting;
            return returncode;
        } else {
            return -1;
        }
    }
}
