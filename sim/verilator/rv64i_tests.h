#pragma once

#include <cstdint>
#include <string>
#include <utility>
#include <vector>

struct Test {
    std::string name;
    std::vector<std::uint32_t> program;
    std::uint64_t expected;
    std::uint8_t expected_mask;
    std::vector<std::pair<std::uint64_t, std::uint8_t>> initial_memory;
};

std::vector<Test> make_tests();
