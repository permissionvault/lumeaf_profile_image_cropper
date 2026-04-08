# 📦 Flutter Package - GitHub Versioning & Usage Guide

This guide explains how to:

1. First-time deploy your Flutter/Dart package to GitHub with versioning
2. Use the package via `pubspec.yaml`
3. Update the package with new versions

---

## 🚀 1. First-Time Setup & Deployment

### Step 1: Set version in `pubspec.yaml`

```yaml
version: 1.0.0
```

---

### Step 2: Initialize & Push Code (if not already done)

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin git@github.com:YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

---

### Step 3: Create Version Tag

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

### Step 4: Use Package in Another Project

Add this in your main project's `pubspec.yaml`:

```yaml
dependencies:
  your_package_name:
    git:
      url: git@github.com:YOUR_USERNAME/YOUR_REPO.git
      ref: v1.0.0
```

Then run:

```bash
flutter pub get
```

---

## 🔁 2. Updating the Package (New Version)

### Step 1: Update Version

```yaml
version: 1.0.1
```

---

### Step 2: Commit Changes

```bash
git add .
git commit -m "Update: bug fixes / improvements"
git push
```

---

### Step 3: Create New Tag

```bash
git tag v1.0.1
git push origin v1.0.1
```

---

### Step 4: Update Dependency in Main Project

```yaml
dependencies:
  your_package_name:
    git:
      url: git@github.com:YOUR_USERNAME/YOUR_REPO.git
      ref: v1.0.1
```

Run:

```bash
flutter pub get
```

---

## 🧪 Recommended Commands After Update

```bash
flutter clean
flutter pub get
```

---

## ⚠️ Common Issues & Fixes

### 1. Permission Denied (SSH)

```bash
ssh -T git@github.com
```

---

### 2. Use HTTPS if SSH Fails

```yaml
url: https://github.com/YOUR_USERNAME/YOUR_REPO.git
```

---

### 3. Tag Not Found

Make sure you pushed the tag:

```bash
git push origin v1.0.0
```

---

## 📌 Best Practices

* Always use **tags**, not `main` branch
* Keep version in `pubspec.yaml` and git tag in sync
* Follow semantic versioning:

  * `1.0.0` → stable release
  * `1.0.1` → bug fix
  * `1.1.0` → new feature
  * `2.0.0` → breaking change

---

## 🎯 Example Workflow Summary

### First Release

```bash
git commit -m "Release v1.0.0"
git push
git tag v1.0.0
git push origin v1.0.0
```

### Next Release

```bash
# update pubspec version to 1.0.1

git commit -m "Fix bugs"
git push
git tag v1.0.1
git push origin v1.0.1
```

---

## 🙌 Done!

Your package is now properly versioned and ready to be used across projects via GitHub.
