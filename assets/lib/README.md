# Static Assets for Chirpy Jekyll Theme

## Introduction

Static assets (libraries/plugins/web-fonts) required by the [_Chirpy_][chirpy] based website to run. It provides the opportunity to choose self-host assets in production or development mode.

## Usage

- If you want to use these assets only in local development:

  Go to the root of your site and clone the assets as follows:

  ```console
  $ git submodule init
  $ git submodule update
  ```

  And then set your site configuration options:

  ```yml
  # _config.yml
  assets:
    self_host:
      enabled: true
      env: development
  ```

- If you expect the assets to be self-hosted when your website is published:

  Keep the `_config.yml` options as follows:

  ```yml
  # _config.yml
  assets:
    self_host:
      enabled: true
  ```

  And then update the GitHub Actions workflow in `.github/workflows/pages-deploy.yml`:

  ```diff
  steps:
    - name: Checkout
      uses: actions/checkout@v2
      with:
  +     submodules: true
  ```

## Versions

| Dependency | Version |
| :------------------------------------------------------- | --------: |
| [Clipboard] | `2.0.11` |
| [Day.js][dayjs] | `1.11.13` |
| [Font Awesome Free][fontawesome] | `6.7.1` |
| [GLightbox] | `3.3.0` |
| [Loading-attribute-polyfill] | `2.1.1` |
| [Mermaid] | `11.4.0` |
| [Simple-Jekyll-Search] | `1.10.0` |
| [Tocbot] | `4.32.2` |

<!-- deps -->

[chirpy]: https://github.com/cotes2020/jekyll-theme-chirpy
[clipboard]: https://www.jsdelivr.com/package/npm/clipboard
[dayjs]: https://www.jsdelivr.com/package/npm/dayjs
[fontawesome]: https://fontawesome.com/download
[glightbox]: https://www.jsdelivr.com/package/npm/glightbox
[loading-attribute-polyfill]: https://www.jsdelivr.com/package/npm/loading-attribute-polyfill
[mermaid]: https://www.jsdelivr.com/package/npm/mermaid
[simple-jekyll-search]: https://www.jsdelivr.com/package/npm/simple-jekyll-search
[tocbot]: https://www.jsdelivr.com/package/npm/tocbot
