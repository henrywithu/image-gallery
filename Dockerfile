# Dockerfile for Next.js project

# ---- Base Stage ----
# Get a base image with Node.js and pnpm
FROM node:18-alpine AS base

# ---- Dependencies Stage ----
# Install dependencies first, in a separate step to take advantage of Docker's caching.
FROM base AS deps
WORKDIR /app

# Copy package manager files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install

# ---- Builder Stage ----
# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

# Copy dependencies from the 'deps' stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# These ARGs are passed from the GitHub Actions workflow during the build
ARG NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME
ARG CLOUDINARY_API_KEY
ARG CLOUDINARY_API_SECRET
ARG CLOUDINARY_FOLDER

# Set environment variables for the build process.
# Next.js will inline these into the build output.
ENV NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=$NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME
ENV CLOUDINARY_API_KEY=$CLOUDINARY_API_KEY
ENV CLOUDINARY_API_SECRET=$CLOUDINARY_API_SECRET
ENV CLOUDINARY_FOLDER=$CLOUDINARY_FOLDER

RUN npm run build

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

ENV PORT 3000

CMD ["node", "server.js"]