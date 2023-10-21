# Use the official OCaml image as base
FROM ubuntu:22.04 AS build-env

# Set working directory inside the container
WORKDIR /app

# Copy the dune opem file into the container
#USER root
COPY google-drive-ocamlfuse.opam google-drive-ocamlfuse.opam
RUN  chmod -R 755 /app && chown -R root:root /app
#USER opam
# Install system dependencies and OPAM packages
RUN apt-get update && \
    apt-get install opam m4 libcurl-ocaml-dev libgmp-ocaml-dev libsqlite3-ocaml-dev libfuse-dev pkg-config zlib1g-dev -yy && \
    opam init --disable-sandboxing && \
    eval $(opam env) && \
    opam switch create 4.10.2 && \
    eval $(opam env --switch=4.10.2) && \
    opam update && \
    opam install . --deps-only -y && \
    opam install dune -y

# Copy the dune project and source files into the container
#USER root
COPY . .
RUN chmod -R 755 /app && chown -R root:root /app
#USER opam

# Build the project using Dune
RUN eval $(opam env) && \
    dune build @install

#RUN ls -aslh bin && ls -aslh _build/default/bin  && ls -aslh _build/install/default/bin && exit 1

FROM ubuntu:22.04

ENV DRIVE_PATH="/mnt/gdrive"

RUN  apt-get update \
 && apt-get install sudo netcat libcurl-ocaml libgmp-ocaml libsqlite3-ocaml fuse -yy  \
 && apt-get clean all \
 && echo "user_allow_other" >> /etc/fuse.conf \
 && rm /var/log/apt/* /var/log/alternatives.log /var/log/bootstrap.log /var/log/dpkg.log

COPY --from=build-env /app/_build/default/bin/gdfuse.exe /usr/local/bin/
RUN ln -s /usr/local/bin/gdfuse.exe /usr/local/bin/google-drive-ocamlfuse

COPY xdg-open /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +rx /usr/local/bin/xdg-open /usr/local/bin/docker-entrypoint.sh

CMD ["docker-entrypoint.sh"]
