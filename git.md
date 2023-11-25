git add .
git commit -m 'pipeline test'
git push origin dev

git add .
git commit -m 'added terraform files for dev server'
git push --set-upstream origin feature/msp-5   ## git push -u origin feature/msp-5  // buda yazılabilir
git checkout dev
git merge feature/msp-5
git push origin dev
```

