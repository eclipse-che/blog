![GitHub deployments](https://img.shields.io/github/deployments/eclipse-che/che-incubator.github.io/github-pages)

[![Contribute (nightly)](https://img.shields.io/static/v1?label=nightly%20Che&message=for%20maintainers&logo=eclipseche&color=FDB940&labelColor=525C86)](https://che-dogfooding.apps.che-dev.x6e0.p1.openshiftapps.com#https://github.com/eclipse-che/blog&storageType=ephemeral)

## How to submit and review a new blog post

Add a new file in `_posts` folder. Images go in `assets/img/<blog-subfolder>`.
Test to see if everything looks good.
Submit a pull request and ping reviewers on mattermost to get it approved.

## How to test a blog post

Before opening a 'pull request' you may want to see how the blog post renders with Jekyll.

### locally

Using docker or Podman:

From the root directory of the repository:
```
$ docker run --rm -it -p 4000:4000 -p 35729:35729 -v $(pwd):/projects quay.io/eclipse/che-blog:next jekyll serve --incremental --watch --host 0.0.0.0 --livereload --livereload-port 35729
```
Content is available at http://localhost:4000


### online

[![Contribute](https://www.eclipse.org/che/contribute.svg)](https://workspaces.openshift.com#https://github.com/eclipse-che/blog)

Open the devfile on a che server instance running DevWorkspaces: (devfile v2)

`https://che-host#https://github.com/eclipse-che/blog`

Vale and AsciiDoc Visual Studio Code extensions will report problems directly in the editor

## How to review a blog post

Click on the `surge` check and browse the content online


