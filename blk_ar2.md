# 🛠️ Skipping the Publish Stage Using `$BLOCK_ARTI2`

If you're consuming shared libraries **a**, **b**, or **c**, you can now skip the artifact publish stage in your GitLab CI pipeline by setting the environment variable `$BLOCK_ARTI2`.

This is useful for feature branches, merge requests, or any situation where publishing is unnecessary — helping reduce deployment time and resource usage.

---

## 🔧 Instructions

### 1. Set the Variable

Add the following to your `.gitlab-ci.yml`:

```yaml
variables:
  BLOCK_ARTI2: "true"
```

Alternatively, define it in **GitLab > Settings > CI/CD > Variables** if you want to control it outside of source code.

---

### 2. Update the `publish` Job

Modify the `publish` job to only run if `$BLOCK_ARTI2` is not set to `"true"`:

```yaml
publish:
  stage: deploy
  script:
    - ./scripts/publish.sh
  rules:
    - if: '$BLOCK_ARTI2 != "true"'
```

---

## ✅ Example Pipeline

Here's a full example of a `.gitlab-ci.yml` file with the variable and condition in place:

```yaml
variables:
  BLOCK_ARTI2: "true"

stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - echo "Build step"

test:
  stage: test
  script:
    - echo "Test step"

publish:
  stage: deploy
  script:
    - ./scripts/publish.sh
  rules:
    - if: '$BLOCK_ARTI2 != "true"'
```

---

## 📌 Summary

- Set `BLOCK_ARTI2: "true"` to skip the `publish` stage.
- Use this for feature branches, testing, or when publishing is not needed.
- This gives you faster pipelines and better control over deployments.
