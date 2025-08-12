# Dockerfile for the Next.js Image Gallery

# ---- Builder Stage ----
# This stage installs dependencies and builds the application.
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# For Next.js on Alpine, libc6-compat is recommended for compatibility
RUN apk add --no-cache libc6-compat

# Copy package.json and the lock file
COPY package.json package-lock.json* ./

# Install all dependencies using npm ci for reproducible builds
RUN npm ci

# Copy the rest of the application source code
COPY . .

# Provide Cloudinary credentials as build arguments.
# These are required for getStaticProps to fetch images during the build.
ARG NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME
ARG CLOUDINARY_API_KEY
ARG CLOUDINARY_API_SECRET
ARG CLOUDINARY_FOLDER

# Disable Next.js telemetry during the build
ENV NEXT_TELEMETRY_DISABLED 1

# Build the Next.js application.
# The build-time ARGs are automatically available as environment variables.
RUN npm run build

# Remove development dependencies to reduce the size of node_modules
RUN npm prune --production

# ---- Runner Stage ----
# This is the final stage that creates the lean production image.
FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

USER nextjs
EXPOSE 3000
ENV PORT 3000
CMD ["npm", "start"]
