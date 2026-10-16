#include <iostream>
#include <vector>
#include <string>
#include <unordered_map>
#include <onnxruntime_cxx_api.h>

const std::string VOCAB_CHARS = " -abcdefghijklmnopqrstuvwxyz0123456789";

std::unordered_map<char, int64_t> build_char2idx() {
    std::unordered_map<char, int64_t> m;
    for (size_t i = 0; i < VOCAB_CHARS.size(); ++i) m[VOCAB_CHARS[i]] = i;
    return m;
}

std::unordered_map<int64_t, char> build_idx2char() {
    std::unordered_map<int64_t, char> m;
    for (size_t i = 0; i < VOCAB_CHARS.size(); ++i) m[i] = VOCAB_CHARS[i];
    return m;
}

std::string predict_sequence(std::string current_buffer, Ort::Session& session, int max_chars = 8) {
    auto char2idx = build_char2idx();
    auto idx2char = build_idx2char();
    std::string generated = "";

    for (int step = 0; step < max_chars; ++step) {
        std::vector<int64_t> input_ids;
        for (char c : current_buffer) {
            if (char2idx.count(c)) input_ids.push_back(char2idx[c]);
        }

        if (input_ids.empty()) break;

        std::vector<int64_t> input_shape = {1, static_cast<int64_t>(input_ids.size())};
        auto memory_info = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);

        Ort::Value input_tensor = Ort::Value::CreateTensor<int64_t>(
            memory_info, input_ids.data(), input_ids.size(), input_shape.data(), input_shape.size()
        );

        const char* input_names[] = {"input_seq"};
        const char* output_names[] = {"output_logits"};

        auto output_tensors = session.Run(
            Ort::RunOptions{nullptr}, input_names, &input_tensor, 1, output_names, 1
        );

        float* logits = output_tensors[0].GetTensorMutableData<float>();
        
        int max_idx = 0;
        float max_val = logits[0];
        for (size_t i = 1; i < VOCAB_CHARS.size(); ++i) {
            if (logits[i] > max_val) {
                max_val = logits[i];
                max_idx = i;
            }
        }

        char next_char = idx2char[max_idx];
        generated += next_char;
        current_buffer += next_char;
    }

    return generated;
}

int main(int argc, char* argv[]) {
    if (argc < 2) return 0;
    std::string current_buffer = argv[1];

    // Resolve absolute path to command_lstm.onnx
    const char* home_env = std::getenv("HOME");
    std::string home_dir = home_env ? home_env : "/root";
    std::string model_path = home_dir + "/autocommand/command_lstm.onnx";

    try {
        Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "LSTMInference");
        Ort::SessionOptions session_options;
        Ort::Session session(env, model_path.c_str(), session_options);

        std::string completion = predict_sequence(current_buffer, session, 6);
        std::cout << completion << std::endl;
    } catch (...) {
        return 0; // Fail silently on error to prevent breaking terminal output
    }

    return 0;
}