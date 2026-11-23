FROM mambaorg/micromamba:2.0.5
ARG TOOL
COPY --chown=$MAMBA_USER:$MAMBA_USER envs/${TOOL}.yml /tmp/environment.yml
RUN micromamba install -y -n base -f /tmp/environment.yml && micromamba clean -a -y
ENV PATH=/opt/conda/bin:$PATH
COPY --chown=$MAMBA_USER:$MAMBA_USER bin/ /usr/local/bin/
