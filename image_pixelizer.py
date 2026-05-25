import cv2

cap = cv2.imread('image.png', cv2.IMREAD_GRAYSCALE)

new_width, new_height = 28, 28  # 28 x 28 = 784 pixels
resized_frame = cv2.resize(cap, (new_width, new_height))

cv2.imshow('Output', resized_frame)
cv2.waitKey(0)
cv2.destroyAllWindows()

def to_q1_14_binary(num):
    # num in [0,1] → round(num * 2**14), positive, 16-bit 2's complement
    fixed = round(num * (1 << 10))
    # clamp just in case
    fixed = max(0, min(fixed, (1 << 15) - 1))
    return f"{fixed & 0xFFFF:016b}"

with open("input_1.mif", 'w') as f:
    for pixel_row in resized_frame:
        for pixel in pixel_row:
            normalized = pixel / 255.0
            binary = to_q1_14_binary(normalized)
            f.write(binary + "\n")

