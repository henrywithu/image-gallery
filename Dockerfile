# Dockerfile for Next.js application

# 1. Builder Stage: Build the application
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Install build tools needed for some npm packages to compile from source.
# 'build-base' provides a C compiler (gcc), 'nasm' is an assembler, and
# 'autoconf' and 'automake' are part of the GNU Build System.
RUN apk add --no-cache build-base nasm autoconf automake

# Install dependencies
# Use --frozen-lockfile for deterministic installs
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN if [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    elif [ -f pnpm-lock.yaml ]; then npm install -g pnpm && pnpm install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci; \
    else npm install; fi

# Copy the rest of the application source code
COPY . .

# Declare build-time arguments
ARG CLOUDINARY_API_KEY
ARG CLOUDINARY_API_SECRET
ARG NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME
ARG CLOUDINARY_FOLDER

# Set them as environment variables for the build process
ENV CLOUDINARY_API_KEY=$CLOUDINARY_API_KEY
ENV CLOUDINARY_API_SECRET=$CLOUDINARY_API_SECRET
ENV NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=$NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME
ENV CLOUDINARY_FOLDER=$CLOUDINARY_FOLDER

# Build the Next.js application
RUN npm run build

# 2. Runner Stage: Create the final, small production image
FROM node:20-alpine AS runner

WORKDIR /app

# Set NODE_ENV to production
ENV NODE_ENV=production

# Copy the standalone output from the builder stage.
COPY --from=builder /app/.next/standalone ./

# Copy the public and static assets
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/static ./.next/static

# Expose the port the app runs on
EXPOSE 3000

# Start the app
CMD ["node", "server.js"]