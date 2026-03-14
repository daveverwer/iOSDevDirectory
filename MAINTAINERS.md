# Maintainers

Thank you for your interest in helping maintain the iOS Dev Directory! This document outlines what's involved in keeping the project running smoothly.

## Pull Request Review

The vast majority of maintenance work is reviewing and merging pull requests. Most pull requests are submissions of new blogs or sites to the directory.

When reviewing a PR, check for the following:

- **Relevance**: Is the content of the site relevant to iOS/Swift development? See the [notes on the submissions page for more details](/contributing/).
- **Correct category**: Is the submission in the appropriate category? The most common mistake is company or team blogs being added to a personal blogs category.

If everything looks good, approve and merge. If the category is wrong, leave a comment asking the submitter to move it.

Always remember, we would prefer more blogs and sites over fewer, and so always err on the side of letting sites in if the decision isn’t clear.

## Automated Tasks

Two automated processes run in the background:

- **Sort checker**: Verifies that all entries are correctly sorted and raises a PR if anything is out of order.
- **Redirect checker**: Checks all listed blogs for HTTP redirects and updates entries accordingly.

These require no manual intervention unless something unusual comes up in the PRs they raise.

## Annual Cleanup

Roughly once a year, a manual cleanup pass is needed to remove dead or abandoned blogs from the directory. There are scripts in the Rakefile to assist with this, but it still requires human judgment to make the final decisions. Personal sites can have temporary downtime that doesn't necessarily mean they're gone for good, so use your best judgment and err on the side of caution before removing anything.

## Project Principles

The iOS Dev Directory is and should always remain a free community resource. It should not include advertising, sponsorship, or any other form of commercial promotion.

## Questions?

If you're unsure about anything, don't hesitate to reach out to the other maintainers.
