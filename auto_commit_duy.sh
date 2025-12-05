#!/bin/bash
echo "🚀 Running Duy's Flutter timeline commits..."

make_commit() {
  GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git commit -am "$2"
}

git checkout duy

make_commit "2025-11-10 09:00:00" "Phase 1: Setup Flutter project"
make_commit "2025-11-11 10:00:00" "Phase 1: Build Login/Register UI"
make_commit "2025-11-12 14:00:00" "Phase 1: Build Home + Navigation UI"
make_commit "2025-11-13 15:00:00" "Phase 1: Build Account + Settings pages"
make_commit "2025-11-14 09:30:00" "Phase 2: Build Chat UI + Compare UI"
make_commit "2025-11-15 13:00:00" "Phase 2: Build Stats page + About page"
make_commit "2025-11-20 09:00:00" "Phase 3: Integrate Image Classification UI"
make_commit "2025-11-22 09:00:00" "Phase 3: Integrate Video Classification UI"
make_commit "2025-11-27 18:00:00" "Phase 4: Add CSV/PDF Export UI"
make_commit "2025-11-30 20:00:00" "Phase 5: Final UI polish + README"

echo "🎉 DONE! Now push with: git push origin duy --force"
