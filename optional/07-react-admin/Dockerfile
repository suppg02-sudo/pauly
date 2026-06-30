FROM node:22-alpine AS builder
WORKDIR /app

# Clone react-admin and install demo dependencies
RUN apk add --no-cache git
RUN git clone --depth 1 https://github.com/marmelab/react-admin.git /app
WORKDIR /app/examples/demo

# Install dependencies
RUN yarn install --immutable

# Build the demo
RUN yarn build

FROM node:22-alpine
WORKDIR /app

# Install a simple static server
RUN npm install -g serve

COPY --from=builder /app/examples/demo/dist ./dist

ENV PORT=5200
EXPOSE 5200

CMD ["sh", "-c", "serve -s dist -l ${PORT:-5200}"]
