# The Web Scale Rails Template

I find myself doing a lot of initialization over months with Rails projects, so this repository is here to consolidate a lot of my opinions. This is what has been done to a standard rails install:

- Rails was initialized with `--skip-tests --skip-system-tests --javascript=esbuild`. You may want to reinstall tests on some projects, but for a lot it is unneeded.
- Tailwind and Font Awesome were both installed and configured to play nicely with each other.
- dotenv was installed in development.
- `view_component` was installed and setup with Tailwind.
- The application template/controller was setup to support dark mode, custom titles/descriptions (including opengraph support, just set `self.title` or `self.description` to overwrite the default in your application controller), and to remove flex from the main tag since it caused odd behaviour to someone using the framework for the first time.
- A home controller/route was added.

## How to use this template

This guide assumes you have rbenv installed on your system. If you are on Windows, I strongly suggest using WSL.

1. Clone the repository and go ahead and delete `.git`.
2. Delete `LICENSE`.
3. Open in a code editor and change all usages of `your_application_name` to your applications name in lower case snake case.
4. Install the Ruby version if prompted by rbenv.
5. Run `bundle install && yarn install`.
6. Run `bin/dev`. It should just work(tm).
