# Dockerfile for Next.js application
# Use official Node.js LTS image
FROM node:20-alpine

# Install build tools needed for some npm packages to compile from source.
# 'build-base' provides a C compiler (gcc), 'nasm' is an assembler, and
# 'autoconf' and 'automake' are part of the GNU Build System.
RUN apk add --no-cache build-base nasm autoconf automake

# Set working directory
WORKDIR /app

# Install dependencies
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./
RUN if [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then npm install -g pnpm && pnpm install; \
    elif [ -f yarn.lock ]; then yarn install; \
    else npm install; fi

# Copy the rest of the application
COPY . .

# Build the application.
# Secrets are mounted securely using Docker BuildKit's --mount=type=secret.
# They are only available during this RUN command and are not stored in the image layers.
# The GitHub Actions workflow provides these secrets.
RUN --mount=type=secret,id=CLOUDINARY_API_KEY \
    --mount=type=secret,id=CLOUDINARY_API_SECRET \
    --mount=type=secret,id=NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME \
    --mount=type=secret,id=CLOUDINARY_FOLDER \
    export CLOUDINARY_API_KEY=$(cat /run/secrets/CLOUDINARY_API_KEY) && \
    export CLOUDINARY_API_SECRET=$(cat /run/secrets/CLOUDINARY_API_SECRET) && \
    export NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=$(cat /run/secrets/NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME) && \
    export CLOUDINARY_FOLDER=$(cat /run/secrets/CLOUDINARY_FOLDER) && \

# Build the Next.js app
RUN npm run build

# Expose port (default for Next.js)
EXPOSE 3000

# Start the Next.js app
CMD ["npm", "start"]