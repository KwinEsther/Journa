# Journa - Blockchain Voting Contract

**Journa** is a voting contract deployed on the Stacks blockchain using the Clarity smart contract language. It allows users to vote for their favorite fruits, track votes, and see the leading fruit in real time.

## Features

- Users can vote for fruits from a predefined list.
- Each user can cast a maximum of 5 votes.
- Track votes for each fruit.
- View the current vote count for any fruit.
- See how many votes a user has cast.
- Get the current leading fruit based on votes.

## Components

- **fruits**: A predefined list of fruits users can vote for (e.g., apple, banana, cherry).
- **fruit-votes**: A map storing the total vote count for each fruit.
- **user-votes**: A map to track the number of votes a user has cast.
- **MAX_VOTES_PER_USER**: A constant that limits each user to 5 votes.
- **vote-for-fruit**: A public function that allows users to vote for a fruit.
- **get-fruit-votes**: A read-only function that returns the total votes for a specified fruit.
- **get-fruits**: A read-only function that returns the list of available fruits.
- **get-user-vote-count**: A read-only function that returns the number of votes cast by a specific user.
- **get-leading-fruit**: A read-only function that returns the fruit with the most votes.

## Contract Code Overview

### `fruits` (Data Variable)
The list of fruits available for voting. It contains a maximum of 10 fruit names, each up to 20 characters.

```clarity
(define-data-var fruits (list 10 (string-ascii 20)) (list "apple" "banana" "cherry" "date" "elderberry"))
