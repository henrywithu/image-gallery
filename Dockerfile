# Dockerfile for Next.js project

# ---- Base Stage ----
FROM node:18-alpine AS base

# ---- Dependencies Stage ----
# Install dependencies first, in a separate step to take advantage of Docker's caching.
FROM base AS deps
WORKDIR /app

# Install build tools needed for some native Node.js modules.
RUN apk add --no-cache python3 make g++

# Copy package manager files
COPY package.json package-lock.json* ./

# Install dependencies using `npm ci` for faster, more reliable builds.
RUN npm ci

# ---- Builder Stage ----
# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

# Copy dependencies from the 'deps' stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# These ARGs are passed from the GitHub Actions workflow during the build
# NEXT_PUBLIC_ vars are inlined by Next.js at build time and are safe to be public.
ARG NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME
ARG CLOUDINARY_FOLDER

# Set public environment variables for the build process.
ENV NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=$NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME
ENV CLOUDINARY_FOLDER=$CLOUDINARY_FOLDER

# Build the application using secrets for API keys.
# Secrets are mounted securely from the build context and are not stored in image layers.
RUN --mount=type=secret,id=CLOUDINARY_API_KEY \
    --mount=type=secret,id=CLOUDINARY_API_SECRET \
    export CLOUDINARY_API_KEY=$(cat /run/secrets/CLOUDINARY_API_KEY) && \
    export CLOUDINARY_API_SECRET=$(cat /run/secrets/CLOUDINARY_API_SECRET) && \
    npm run build

# ---- Runner Stage ----
# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000

CMD ["node", "server.js"]