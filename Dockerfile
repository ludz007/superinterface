############################################
# Stage 1: Builder — install & build only the Next.js example
############################################
FROM node:18-alpine AS builder

# 1) Set working directory to the Next.js example folder
WORKDIR /app/examples/next

# 2) Copy only the Next.js example’s package files
COPY examples/next/package.json examples/next/package-lock.json ./

# 3) Install dependencies for the example
RUN npm install

# 4) Copy the rest of the example’s source code
COPY examples/next ./

# 5) Build the Next.js example (generates .next/)
RUN npm run build


############################################
# Stage 2: Runner — copy production output & start Next.js
############################################
FROM node:18-alpine AS runner

# 1) Create a fresh working directory
WORKDIR /app/examples/next

# 2) Copy over the built .next folder and production node_modules from the builder stage
COPY --from=builder /app/examples/next/.next ./.next
COPY --from=builder /app/examples/next/node_modules ./node_modules
COPY --from=builder /app/examples/next/public ./public
COPY --from=builder /app/examples/next/package.json ./package.json

# 3) Set NODE_ENV=production so Next.js serves in production mode
ENV NODE_ENV=production

# 4) Expose Next.js’s default port
EXPOSE 3000

# 5) Start the Next.js server
CMD ["npm", "start"]
