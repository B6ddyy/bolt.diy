FROM node:20-bookworm

WORKDIR /app

# Habilita pnpm de forma estável
ENV PNPM_HOME=/usr/local/share/pnpm
ENV PATH=$PNPM_HOME:$PATH
RUN corepack enable && corepack prepare pnpm@9.9.0 --activate

# Toolchain para módulos nativos + git/CA
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 make g++ git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Opcional: tornar o pnpm mais resiliente à rede
RUN pnpm config set fetch-retries 5 \
 && pnpm config set fetch-timeout 180000 \
 && pnpm config set network-timeout 180000 \
 && pnpm config set prefer-offline false \
 && pnpm config set auto-install-peers true

# (Sugestão) Não instalar wrangler global; use devDep + pnpm exec
# Se quiser manter global, descomente a linha abaixo:
# RUN npm i -g wrangler@4

# Copia manifests primeiro (cache de deps)
COPY package.json pnpm-lock.yaml ./

# Instala deps (sem travar no lock antigo)
RUN pnpm install --no-frozen-lockfile --reporter=append --loglevel=info

# Copia o restante do código
COPY . .

# Normaliza e dá permissão ao bindings.sh (se existir)
RUN [ -f bindings.sh ] && tr -d '\r' < bindings.sh > bindings.tmp && mv bindings.tmp bindings.sh && chmod +x bindings.sh || true

# Build do app (ajuste se seu script tiver outro nome)
RUN pnpm run build

EXPOSE 5173

ENV NODE_ENV=production \
    RUNNING_IN_DOCKER=true

# Inicia com o script do package.json
CMD ["pnpm","run","dockerstart"]
