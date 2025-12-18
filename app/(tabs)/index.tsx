import AsyncStorage from "@react-native-async-storage/async-storage";
import { useEffect, useState } from "react";
import { ActivityIndicator, Pressable, StyleSheet, View } from "react-native";

import { ThemedText } from "@/components/themed-text";
import { ThemedView } from "@/components/themed-view";
import { useThemeColor } from "@/hooks/use-theme-color";

const STORAGE_KEY = "@counter_value";

export default function HomeScreen() {
  const [count, setCount] = useState(0);
  const [loading, setLoading] = useState(true);

  const primaryColor = useThemeColor({}, "tint");
  const backgroundColor = useThemeColor({}, "background");

  // Load counter value from storage on mount
  useEffect(() => {
    loadCounter();
  }, []);

  // Save counter value to storage whenever it changes
  useEffect(() => {
    if (!loading) {
      saveCounter();
    }
  }, [count, loading]);

  const loadCounter = async () => {
    try {
      const value = await AsyncStorage.getItem(STORAGE_KEY);
      if (value !== null) {
        setCount(parseInt(value, 10));
      }
    } catch (error) {
      console.error("Failed to load counter:", error);
    } finally {
      setLoading(false);
    }
  };

  const saveCounter = async () => {
    try {
      await AsyncStorage.setItem(STORAGE_KEY, count.toString());
    } catch (error) {
      console.error("Failed to save counter:", error);
    }
  };

  const increment = () => setCount((prev) => prev + 1);
  const decrement = () => setCount((prev) => prev - 1);
  const reset = () => setCount(0);

  if (loading) {
    return (
      <ThemedView style={styles.container}>
        <ActivityIndicator size="large" color={primaryColor} />
      </ThemedView>
    );
  }

  return (
    <ThemedView style={styles.container}>
      <View style={styles.content}>
        <ThemedText type="title" style={styles.title}>
          Hello Counter
        </ThemedText>

        <View style={styles.counterDisplay}>
          <ThemedText style={styles.counterText}>{count}</ThemedText>
        </View>

        <View style={styles.buttonRow}>
          <Pressable
            onPress={decrement}
            style={({ pressed }) => [
              styles.circleButton,
              styles.decrementButton,
              pressed && styles.buttonPressed,
            ]}
          >
            <ThemedText style={styles.buttonText}>−</ThemedText>
          </Pressable>

          <Pressable
            onPress={increment}
            style={({ pressed }) => [
              styles.circleButton,
              styles.incrementButton,
              pressed && styles.buttonPressed,
            ]}
          >
            <ThemedText style={styles.buttonText}>+</ThemedText>
          </Pressable>
        </View>

        <Pressable
          onPress={reset}
          style={({ pressed }) => [styles.resetButton, pressed && styles.buttonPressed]}
        >
          <ThemedText style={styles.resetButtonText}>Reset</ThemedText>
        </Pressable>
      </View>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  title: {
    marginBottom: 48,
    fontSize: 28,
    lineHeight: 36,
  },
  counterDisplay: {
    marginBottom: 48,
    padding: 24,
    minWidth: 200,
    alignItems: "center",
  },
  counterText: {
    fontSize: 72,
    lineHeight: 86,
    fontWeight: "bold",
    fontVariant: ["tabular-nums"],
  },
  buttonRow: {
    flexDirection: "row",
    gap: 24,
    marginBottom: 32,
  },
  circleButton: {
    width: 80,
    height: 80,
    borderRadius: 40,
    justifyContent: "center",
    alignItems: "center",
  },
  incrementButton: {
    backgroundColor: "#007AFF",
  },
  decrementButton: {
    backgroundColor: "#FF3B30",
  },
  buttonText: {
    color: "#fff",
    fontSize: 36,
    lineHeight: 40,
    fontWeight: "600",
  },
  buttonPressed: {
    transform: [{ scale: 0.95 }],
    opacity: 0.8,
  },
  resetButton: {
    paddingVertical: 12,
    paddingHorizontal: 32,
    borderRadius: 8,
    backgroundColor: "#8E8E93",
    minHeight: 44,
    justifyContent: "center",
  },
  resetButtonText: {
    color: "#fff",
    fontSize: 16,
    lineHeight: 20,
    fontWeight: "600",
  },
});
