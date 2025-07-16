#!/bin/bash

# Add all changes
git add .

# Commit with a timestamp
git commit -m "feat: Work in progress - $(date)"

# Push to the remote repository
git push
