CXX = g++
CXXFLAGS = -std=c++17 -I$(HOME)/onnxruntime/include
LDFLAGS = -L$(HOME)/onnxruntime/lib -lonnxruntime -Wl,-rpath,$(HOME)/onnxruntime/lib
TARGET = bin/cmd_suggest
SRC = main.cpp

all: model build

model:
	python3 train_and_export.py

build: $(SRC)
	mkdir -p bin
	$(CXX) $(CXXFLAGS) $(SRC) $(LDFLAGS) -o $(TARGET)

install:
	mkdir -p $(HOME)/.autocommand
	mkdir -p $(HOME)/bin
	cp $(TARGET) $(HOME)/bin/cmd_suggest
	cp command_lstm.onnx* $(HOME)/.autocommand/

clean:
	rm -rf bin command_lstm.onnx*