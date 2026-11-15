# 2013 – The Release of Docker

DEVOP2 · Unit 01 · Exercise A (DevOps milestone timeline) · François Lange

## Year & Event

March 2013 – Solomon Hykes presents Docker at the PyCon conference in Santa Clara (USA). The project is published as open source the same month.

## Technology Overview

Docker began as an internal tool of dotCloud, a hosting company founded by Solomon Hykes. It packs a program together with everything it needs (libraries, settings, system tools) into one sealed box called a container. The box is built once from a short text file, the Dockerfile, and then runs unchanged on any machine that has Docker. Unlike a virtual machine, a container does not carry a whole operating system, so it starts in seconds and many of them fit on one server. Before Docker, each server was installed by hand from a written procedure, and no two servers were exactly alike. The classic complaint was: "it works on my machine".

## Key Impact on DevOps

In the traditional V-model, a release travelled slowly through four environments: development, test, pre-production and production. Each one was installed separately, so every go-live (*mise en production*) brought surprises. The customer saw nothing for months: the well-known tunnel effect (*effet tunnel*). With Docker, the very same container passes through all four environments; only the configuration changes. Going back is simple: the previous container is started again. Deliveries became small and frequent, the development and operations teams finally shared one object, and automated pipelines (CI/CD), then Kubernetes, were built on this foundation.

## Example in Practice

The Warehouse Group, New Zealand's largest retail chain, uses Docker for its software delivery. Preparing a developer environment used to take weeks; it now takes about one minute. A change moves through development and test and, after a final check by a person, reaches production, often within an hour, with the same image from start to finish.

## Mini Timeline

- **Before:** V-model, manual installations, a few large go-lives per year, tunnel effect.
- **2013:** Docker makes containers simple: build once, run anywhere.
- **After:** Kubernetes (2014), several deployments per day.

## References

1. Docker, customer story "The Warehouse Group": <https://www.docker.com/customer-stories/the-warehouse-group/>
2. Snyk, "The Docker project turns 10": <https://snyk.io/blog/the-docker-project-turns-10/>
