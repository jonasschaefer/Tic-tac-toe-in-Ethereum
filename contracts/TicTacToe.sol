// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
* @title TicTacToe
* @dev A TicTacToe game between two players including a custom stake.
* @custom:dev-run-script contracts/TicTacToe.sol
*/
contract TicTacToe {
    address payable public player1;
    address payable public player2;
    address payable public turn;
    address payable public winner;

    bool public gameOver = false;
    uint public stake;
    enum Status { Pending, Accepted, Playing, Draw, Player1Won, Player2Won, Resigned }
    Status public gameStatus;
    uint8 public moveCounter = 0;
    
    enum Field { None, X, O }
    Field[3][3] gameBoard;

    constructor() {
        player1 = payable(msg.sender);
        gameStatus = Status.Pending;
    }

    // Helper function used for checking whether a coordinate is in bounds
    function inBounds(uint8 xpos, uint8 ypos) public pure returns (bool) {
        return (xpos >= 0 && xpos <= 2 && ypos >= 0 && ypos <= 2);
    }

    // Helper function used for getting a string of a field state
    function fieldToString(uint8 xpos, uint8 ypos) public view returns (string memory) {
        require(inBounds(xpos, ypos), "Field is out of bounds.");

        if(gameBoard[xpos][ypos] == Field.None){
            return " ";
        }
        if(gameBoard[xpos][ypos] == Field.X){
            return "X";
        }
        if(gameBoard[xpos][ypos] == Field.O){
            return "O";
        }
    }

    // Helper function used for transforming a row of the game board to a string
    function rowToString(uint8 row) public view returns (string memory) {
        return string.concat(fieldToString(0, row), "|", fieldToString(1, row), "|", fieldToString(2, row));
    }

    // View function used for outputting the current state of the game as a string
    function gameBoardToString() public view returns (string memory) {
        return string.concat(rowToString(0), "\n", rowToString(1), "\n", rowToString(2), "\n");
    }

    // Function used by player1 for starting the game
    function startGame(uint _stake) public payable {
        require(msg.sender == player1, "Only player1 can start the game.");
        require(_stake > 0, "Stake must be greater than 0.");
        require(gameStatus == Status.Pending, "Game has already started.");
        require(player2 != address(0), "Player2 has not joined yet.");
        stake = _stake;
        gameStatus = Status.Accepted;
    }

    // Function used by player2 for joining the game
    function acceptGame() public payable {
        require(msg.sender != player1, "Player1 cannot accept their own game.");
        require(msg.value == stake, "Stake must be equal to the value sent by player1.");
        require(gameStatus == Status.Accepted, "Game has not been started yet or already accepted.");
        player2 = payable(msg.sender);
        gameStatus = Status.Playing;
        turn = player1;
    }

    // Function used by both players to submit their move
    function move(uint8 xpos, uint8 ypos) public payable {
        require(msg.sender == turn, "It is not your turn to move.");
        require(gameStatus == Status.Playing, "Game has not been accepted yet or has ended.");
        // Validate the move 
        require(inBounds(xpos, ypos), "Your submitted move was invalid (out of bounds).");
        require(gameBoard[xpos][ypos] == Field.None , "Your submitted move was invalid (field already taken).");

        // Apply move to gameBoard
        if (turn == player1) {
            gameBoard[xpos][ypos] = Field.X;
        } else {
            gameBoard[xpos][ypos] = Field.O;
        }

        // Update the turn
        turn = (turn == player1) ? player2 : player1;

        // Increment move counter
        moveCounter++;

        // Check for checkmate and draw here
        if (checkMate()) {
            gameOver = true;
            winner = (turn == player1) ? player2 : player1;
            gameStatus = (turn == player1) ? Status.Player2Won : Status.Player1Won;
        } else if (draw()) {
            gameOver = true;
            gameStatus = Status.Draw;
        }
    }

    // Function used by either player to resign the match
    function resign() public {
        require(msg.sender == turn, "It is not your turn to move.");
        require(gameStatus == Status.Playing, "Game has not been accepted yet or has ended.");
        gameOver = true;
        winner = (turn == player1) ? player2 : player1;
        gameStatus = (turn == player1) ? Status.Player2Won : Status.Player1Won;
    }

    // Internal function used to check if either player has won the game
    function checkMate() internal view returns (bool) {
        // Check rows
        for (uint8 i = 0; i < 3; i++) {
            for (uint8 j = 0; j < 2; j++) {
                if (gameBoard[i][j] != Field.None && gameBoard[i][j] == gameBoard[i][j + 1] && gameBoard[i][j + 1] == gameBoard[i][j + 2]) {
                    return true;
                }
            }
        }

        // Check columns
        for (uint8 j = 0; j < 3; j++) {
            for (uint8 i = 0; i < 2; i++) {
                if (gameBoard[i][j] != Field.None && gameBoard[i][j] == gameBoard[i + 1][j] && gameBoard[i + 1][j] == gameBoard[i + 2][j]) {
                    return true;
                }
            }
        }

        // Check diagonals
        if (gameBoard[0][0] != Field.None && gameBoard[0][0] == gameBoard[1][1] && gameBoard[1][1] == gameBoard[2][2]) {
            return true;
        }
        if (gameBoard[0][2] != Field.None && gameBoard[0][2] == gameBoard[1][1] && gameBoard[1][1] == gameBoard[2][0]) {
            return true;
        }

        return false;
    }

    // Internal function used to check if the game has been drawn
    function draw() internal view returns (bool) {
        return (moveCounter > 8 && !checkMate());
    }

    // Function to terminate the contract and transfer the stake
    function terminate() public {
        require(gameOver, "Game has not ended yet.");
        if (gameStatus == Status.Draw) {
            player1.transfer(stake / 2);
            player2.transfer(stake / 2);
        } else {
            winner.transfer(stake);
        }
        selfdestruct(payable(msg.sender));
    }
}

