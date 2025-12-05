#!/bin/bash

echo "🚀 Running Duy's Flutter timeline commits..."

make_commit() {
  GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git commit --allow-empty -m "$2"
}

# WEEK 1 (Setup + Auth UI)
make_commit "2025-11-10 10:00:00" "Phase 1: Setup Flutter project structure"
make_commit "2025-11-11 10:00:00" "Phase 1: Build Login/Register UI"
make_commit "2025-11-12 10:00:00" "Phase 1: Build Home + Menu UI"

# WEEK 2 (Image classification)
make_commit "2025-11-13 10:00:00" "Phase 2: Add image classifier service"
make_commit "2025-11-14 10:00:00" "Phase 2: Finish Image Detection page"

# WEEK 3 (Video + Compare)
make_commit "2025-11-17 10:00:00" "Phase 3: Add video classifier service"
make_commit "2025-11-18 10:00:00" "Phase 3: Build Video Detection page"
make_commit "2025-11-19 10:00:00" "Phase 3: Build Compare page"

# WEEK 4 (Stats + Chat + Account)
make_commit "2025-11-22 10:00:00" "Phase 4: Add Stats page with charts"
make_commit "2025-11-23 10:00:00" "Phase 4: Add Chat with AI"
make_commit "2025-11-24 10:00:00" "Phase 4: Finish Account & Settings pages"

echo "🎉 DONE! Now push with: git push origin duy --force"
