void main() {
  try {
    print(DateTime.parse("2026-04-30 17:19:09"));
  } catch (e) {
    print("Error parsing space: $e");
  }
}
