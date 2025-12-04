#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <string.h>

#define SERIAL_PORT "/dev/ttyUSB2"   // Change to your port: /dev/ttyUSB0, /dev/ttyUSB1, /dev/ttyACM0,...
#define BAUDRATE B115200

char board[9] = {' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '};

void display_board(void)
{
    printf("\n Current Board\n");
    printf(" %c | %c | %c \n", board[0], board[1], board[2]);
    printf("---+---+---\n");
    printf(" %c | %c | %c \n", board[3], board[4], board[5]);
    printf("---+---+---\n");
    printf(" %c | %c | %c \n\n", board[6], board[7], board[8]);
}

int check_win(char player)
{
    const uint8_t wins[8][3] = {
        {0,1,2}, {3,4,5}, {6,7,8},
        {0,3,6}, {1,4,7}, {2,5,8},
        {0,4,8}, {2,4,6}
    };
    for (int i = 0; i < 8; i++) {
        if (board[wins[i][0]] == player &&
            board[wins[i][1]] == player &&
            board[wins[i][2]] == player)
            return 1;
    }
    return 0;
}

int board_full(void)
{
    for (int i = 0; i < 9; i++)
        if (board[i] == ' ') return 0;
    return 1;
}

static int setup_serial(const char *device)
{
    int fd = open(device, O_RDWR | O_NOCTTY | O_SYNC);
    if (fd < 0) {
        perror("open");
        return -1;
    }
    struct termios tty;
    tcgetattr(fd, &tty);
    cfsetospeed(&tty, BAUDRATE);
    cfsetispeed(&tty, BAUDRATE);
    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;     // 8-bit chars
    tty.c_cflag |= (CLOCAL | CREAD);                // ignore modem controls
    tty.c_cflag &= ~PARENB;                         // no parity
    tty.c_cflag &= ~CSTOPB;                         // 1 stop bit
    tty.c_cflag &= ~CRTSCTS;                        // no hardware flow control
    tty.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); // raw input
    tty.c_iflag &= ~(IXON | IXOFF | IXANY | IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL);
    tty.c_oflag &= ~OPOST;                          // raw output
    tty.c_cc[VTIME] = 100;                          // timeout 10.0 seconds
    tty.c_cc[VMIN]  = 0;
    tcsetattr(fd, TCSANOW, &tty);
    tcflush(fd, TCIFLUSH);
    return fd;
}

int main(void)
{
    int fd = setup_serial(SERIAL_PORT);
    if (fd < 0) {
        printf("Cannot open %s - check port name and permission (use sudo or add user to dialout group)\n", SERIAL_PORT);
        return 1;
    }

    printf("Tic-Tac-Toe vs FPGA (You are X, FPGA is O\n");
    printf("Positions:\n");
    printf(" 0 | 1 | 2 \n---+---+---\n 3 | 4 | 5 \n---+---+---\n 6 | 7 | 8 \n\n");

    while (1) { // Play multiple games
        // Reset local board
        for (int i = 0; i < 9; i++) board[i] = ' ';

        // Send start-game command (0xFF)
        uint8_t cmd = 0xFF;
        write(fd, &cmd, 1);
        usleep(100000); // Wait for FPGA to be ready
        display_board();

        int game_over = 0;
        while (!game_over) {
            /* =============== Player (X) turn =============== */
            int pos;
            while (1) {
                printf("Your move (0-8): ");
                fflush(stdout);
                if (scanf("%d", &pos) != 1 || pos < 0 || pos > 8 || board[pos] != ' ') {
                    printf("Invalid move! Try again.\n");
                    while (getchar() != '\n'); // clear stdin buffer
                } else {
                    break;
                }
            }

            // Send player's move
            uint8_t move = (uint8_t)pos;
            write(fd, &move, 1);

            // Read acknowledgment from FPGA
            uint8_t ack;
            int n = read(fd, &ack, 1);
            if (n != 1) {
                printf("No response from FPGA!\n");
                close(fd);
                return 1;
            }

            if (ack == 0xEE) {
                printf("FPGA rejected the move (cell already occupied or invalid)!\n");
                continue; // try again
            }
            else if (ack >= 0x30 && ack <= 0x38) {
                int confirmed = ack - 0x30;
                if (confirmed != pos) printf("Warning: position mismatch!\n");
                board[pos] = 'X';
                printf("You placed X at position %d\n", pos);
                display_board();
            }
            else {
                printf("Unexpected acknowledgment byte: 0x%02X\n", ack);
            }

            if (check_win('X')) {
                printf("YOU WIN!\n");
                game_over = 1;
                continue;
            }
            if (board_full()) {
                printf("It's a DRAW!\n");
                game_over = 1;
                continue;
            }

            /* =============== FPGA (O) turn =============== */
            printf("FPGA is thinking...\n");
            uint8_t fpga_byte;
            n = read(fd, &fpga_byte, 1);
            if (n != 1) {
                printf("FPGA did not send a move!\n");
                close(fd);
                return 1;
            }

            if (fpga_byte >= 0x40 && fpga_byte <= 0x48) {
                int fpga_pos = fpga_byte - 0x40;
                board[fpga_pos] = 'O';
                printf("FPGA placed O at position %d\n", fpga_pos);
                display_board();
            } else {
                printf("Unexpected FPGA move byte: 0x%02X\n", fpga_byte);
            }

            // Check for game-end status byte (optional, sent only when game ends)
            struct timeval tv = {0, 200000}; // 200 ms timeout
            fd_set set;
            FD_ZERO(&set);
            FD_SET(fd, &set);
            int rv = select(fd + 1, &set, NULL, NULL, &tv);
            if (rv > 0) {
                uint8_t status;
                if (read(fd, &status, 1) == 1) {
                    if (status == 0xA0) { printf("YOU WIN!\n"); game_over = 1; }
                    else if (status == 0xA1) { printf("FPGA (O) WINS!\n"); game_over = 1; }
                    else if (status == 0xAA) { printf("It's a DRAW!\n"); game_over = 1; }
                }
            }

            if (check_win('O')) {
                printf("FPGA wins!\n");
                game_over = 1;
            }
            if (board_full()) {
                printf("It's a DRAW!\n");
                game_over = 1;
            }
        }

        /* =============== Play again? =============== */
        char choice;
        printf("\nPlay again? (y/n): ");
        fflush(stdout);
        scanf(" %c", &choice);
        while (getchar() != '\n'); // clear stdin

        if (choice != 'y' && choice != 'Y') {
            break;
        }

        // === Clear UART RX buffer before reset ===
        uint8_t trash;
        struct timeval tv = {0, 100000}; // 100 ms timeout
        while (1) {
            fd_set set;
            FD_ZERO(&set);
            FD_SET(fd, &set);
            int rv = select(fd + 1, &set, NULL, NULL, &tv);
            if (rv <= 0) break; // no more bytes
            read(fd, &trash, 1);
        }

        // Send reset command
        uint8_t reset_cmd = 0xFE;
        write(fd, &reset_cmd, 1);
        usleep(100000);

        uint8_t reset_ack;
        if (read(fd, &reset_ack, 1) == 1 && reset_ack == 0xFE) {
            printf("Board reset successfully! Starting new game...\n\n");
        } else {
            printf("Reset failed or no response!\n");
        }
    }

    printf("Thanks for playing!\n");
    close(fd);
    return 0;
}