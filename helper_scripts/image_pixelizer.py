import cv2

filename = input("filename: ",).strip()

cap = cv2.imread(filename, cv2.IMREAD_GRAYSCALE)

new_width, new_height = 28, 28  # 28 x 28 = 784 pixels
resized_frame = cv2.resize(cap, (new_width, new_height))

cv2.imshow('Output', resized_frame)
cv2.waitKey(0)
cv2.destroyAllWindows()

def to_fixed_p_binary(num):
    fixed = round(num * (1 << 8))
    fixed = max(0, min(fixed, (1 << 15) - 1))
    return f"{fixed & 0xFFFF:016b}"

with open("input_1.txt", 'w') as f:
    for pixel_row in resized_frame:
        for pixel in pixel_row:
            normalized = pixel / 255.0
            binary = to_fixed_p_binary(normalized)
            f.write(binary + "\n")

