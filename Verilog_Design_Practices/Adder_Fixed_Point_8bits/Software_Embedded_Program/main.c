#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

#define SERIAL_PORT "/dev/ttyUSB2"
#define BAUDRATE    B115200

// Fixed-point parameters: 1 sign, 4 integer, 3 fractional
#define FRAC_BITS   3
#define SCALE       (1 << FRAC_BITS)
#define MAX_VAL     15.875f
#define MIN_VAL    -16.0f

static int setup_serial(const char *device) {
    int fd = open(device, O_RDWR | O_NOCTTY);
    if (fd < 0) {
        perror("open");
        return -1;
    }

    struct termios options;
    tcgetattr(fd, &options);
    options.c_cflag = BAUDRATE | CS8 | CLOCAL | CREAD;
    options.c_iflag = IGNPAR;
    options.c_oflag = 0;
    options.c_lflag = 0;
    tcflush(fd, TCIFLUSH);
    tcsetattr(fd, TCSANOW, &options);
    return fd;
}

// In ra dạng nhị phân 8 bit
void print_binary8(uint8_t val) {
    for (int i = 7; i >= 0; i--)
        printf("%d", (val >> i) & 1);
}

// Chuyển float → uint8_t (1 sign, 4 int, 3 frac)
uint8_t float_to_fixed8(float x) {
    if (x > MAX_VAL) x = MAX_VAL;
    if (x < MIN_VAL) x = MIN_VAL;
    int16_t fixed = (int16_t)(x * SCALE + (x >= 0 ? 0.5f : -0.5f));
    return (uint8_t)(fixed & 0xFF);
}

// Chuyển uint8_t → float (1 sign, 4 int, 3 frac)
float fixed8_to_float(uint8_t val) {
    int8_t s = (int8_t)val; // sign-extend
    return (float)s / SCALE;
}

int main(void) {
    float a, b;

    printf("Enter a (-16.0 to 15.875): ");
    if (scanf("%f", &a) != 1) {
        fprintf(stderr, "Invalid input for a\n");
        return 1;
    }

    printf("Enter b (-16.0 to 15.875): ");
    if (scanf("%f", &b) != 1) {
        fprintf(stderr, "Invalid input for b\n");
        return 1;
    }

    if (a > MAX_VAL || a < MIN_VAL || b > MAX_VAL || b < MIN_VAL) {
        fprintf(stderr, "Error: values out of range (must be between %.3f and %.3f)\n", MIN_VAL, MAX_VAL);
        return 1;
    }

    uint8_t a_fixed = float_to_fixed8(a);
    uint8_t b_fixed = float_to_fixed8(b);

    printf("\nEncoded fixed-point values:\n");
    printf("a = %.3f → 0x%02X → ", a, a_fixed);
    print_binary8(a_fixed);
    printf("\n");
    printf("b = %.3f → 0x%02X → ", b, b_fixed);
    print_binary8(b_fixed);
    printf("\n");

    int fd = setup_serial(SERIAL_PORT);
    if (fd < 0) return 1;

    // Gửi a và b
    uint8_t buf[2] = {a_fixed, b_fixed};
    if (write(fd, buf, 2) != 2) {
        perror("write");
        close(fd);
        return 1;
    }

    printf("\nSent via UART...\n");

    // Đọc lại c từ UART (8-bit)
    uint8_t c_fixed;
    ssize_t n = read(fd, &c_fixed, 1);
    if (n != 1) {
        perror("read");
        close(fd);
        return 1;
    }

    float c = fixed8_to_float(c_fixed);
    printf("\nReceived c:\n");
    printf("c = %.3f → 0x%02X → ", c, c_fixed);
    print_binary8(c_fixed);
    printf("\n");

    close(fd);
    return 0;
}
