# Contributing to BufferSerializer
Thank you for your interest in contributing to BufferSerializer!

## Questions
If you have any questions, feel free to create a new discussion or reach out
 to the maintainers.

## Documentation
Please refer to the [README.md](./README.md) for detailed information about
 the project. Additional documentation can be found in the
 [docs](https://github.com/nwinn-student/luau-buffer-serialize/tree/main/docs)
 directory.  Examples can be found in the
 [examples](https://github.com/nwinn-student/luau-buffer-serialize/tree/main/examples)
 directory.

Please feel free to suggest improvements to the documentation in a new issue
 or pull request.
If you find any part of the documentation unclear, please let us know.

## How to Contribute Code

1. Fork the repository and create a branch from `main`.
2. Write clear, concise code.
3. Run [Stylua](https://github.com/JohnnyMorganz/StyLua) for formatting
 and luau-analyze to catch common issues.
   1. Stylua can be run with `stylua .` in the root directory of the
 repository, using `cd path/to/repo`, assuming Stylua is installed.
   2. Luau-analyze can be run with `luau-analyze .` in the root
 directory of the repository, assuming luau-analyze is installed.
4. Submit a pull request with a clear description.

## Coding Standards

- Follow the [Roblox Lua Style Guide](https://roblox.github.io/lua-style-guide/).

## Reporting Issues

- Search existing issues first.
- Provide a clear title, description, and steps to reproduce, if applicable.
- Include relevant logs or screenshots.
- Suggest possible solutions if you have any.

## Pull Requests

- Should an issue be attached, add `Closes #1`.
- Run benchmarks if performance is affected, and include results.
- Ensure all tests pass, adding new tests if necessary.
  - The test suite can be run with `luau ./tests` in the root directory,
 assuming Luau is installed.
- Ensure documentation is updated if necessary.
- Keep your branch up to date with `main`.
- Respond to feedback.

## Code Review
- Be respectful and constructive.
- Ask questions if something is unclear.
- Provide context and reasoning for decisions, referencing prior
 Discussions, Pull Requests, or Issues as necessary.
- Approve when ready, do not rush to merge.  The concept the code is trying
 to achieve is more important than the code itself, should the concept be
 flawed, it should be discussed and improved.

Thank you for helping improve BufferSerializer!
