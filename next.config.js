const nextConfig = {
  reactStrictMode: true,
  // This is the crucial part for Docker optimization
  output: 'standalone',
};

module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "res.cloudinary.com",
        pathname: `/${process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME}/**`,
      },
    ],
  },
};
