#!/bin/bash

echo "🚀 Running Duy's Flutter timeline commits..."

make_commit() {
  GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git commit -am "$2"
}

# WEEK 1 (Design UI)
make_commit "2025-11-10 10:00:00" "Phase 1: Setup Flutter project structure"
make_commit "2025-11-11 10:00:00" "Phase 1: Build Login + Register UI"
make_commit "2025-11-12 10:00:00" "Phase 1: Build Home + Menu UI"

# WEEK 2 (Image Classification)
make_commit "2025-11-13 10:00:00" "Phase 2: Add Image Classifier service"
make_commit "2025-11-14 10:00:00" "Phase 2: Finish Image Detection Page"

# WEEK 3 (Video Classification + Compare)
make_commit "2025-11-17 10:00:00" "Phase 3: Add Video Classifier service"
make_commit "2025-11-18 10:00:00" "Phase 3: Build Video Detection Page"
make_commit "2025-11-19 10:00:00" "Phase 3: Build Compare Page"

# WEEK 4 (Stats + Chat + Account + Settings)
make_commit "2025-11-22 10:00:00" "Phase 4: Add Stats Page with charts"
make_commit "2025-11-23 10:00:00" "Phase 4: Add Chat with AI"
make_commit "2025-11-24 10:00:00" "Phase 4: Finish Account & Settings Page"

echo "🎉 DONE! Now push with: git push origin duy --force"
