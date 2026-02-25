const mongoose = require('mongoose');

// MongoDB connection
const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/bolola';
    console.log(`Connecting to MongoDB: ${mongoUri}`);
    
    await mongoose.connect(mongoUri, {
  
    });
    console.log(`MongoDB connected successfully to: ${mongoUri}`);
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

// User Schema
const UserSchema = new mongoose.Schema({
  firebaseUid: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  photoUrl: { type: String, default: '' },
  isAdmin: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },
  favorites: [{ type: String }], // Array of item aliases that user has favorited
  lastLoginAt: { type: Date, default: Date.now },
}, { 
  timestamps: true // This adds createdAt and updatedAt fields automatically
});

// Add index for faster queries
UserSchema.index({ firebaseUid: 1 });
UserSchema.index({ email: 1 });

// Category Schema
const CategorySchema = new mongoose.Schema({
  alias: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  ordering: { type: Number, default: 0 },
  groupNames: [String],
}, { timestamps: false });

// Group Schema
const GroupSchema = new mongoose.Schema({
  alias: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  count: { type: Number, default: 0 },
  iconUrl: String,
  ordering: { type: Number, default: 0 },
  isNewGroup: { type: Number, default: 0 },
  categoryAlias: { type: String, required: true },
}, { timestamps: false });

// Item Schema
const ItemSchema = new mongoose.Schema({
  alias: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  ordering: { type: Number, default: 0 },
  shareCount: { type: Number, default: 0 },
  audioUrl: String,
  videoUrl: String,
  sourceUrl: String,
  imageUrl: String,
  isFavorite: { type: Boolean, default: false },
  keywords: [String],
  relatedKeywords: [String],
  groupAlias: { type: String, required: true },
  categoryAlias: { type: String, required: true },
}, { timestamps: false });

// ChartItem Schema
const ChartItemSchema = new mongoose.Schema({
  alias: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  ordering: { type: Number, default: 0 },
  shareCount: { type: Number, default: 0 },
  audioUrl: String,
  videoUrl: String,
  sourceUrl: String,
  imageUrl: String,
  isFavorite: { type: Boolean, default: false },
  keywords: [String],
  relatedKeywords: [String],
  groupAlias: String,
  categoryAlias: String,
}, { timestamps: false });

// Create models
const User = mongoose.model('User', UserSchema);
const Category = mongoose.model('Category', CategorySchema);
const Group = mongoose.model('Group', GroupSchema);
const Item = mongoose.model('Item', ItemSchema);
const ChartItem = mongoose.model('ChartItem', ChartItemSchema);

module.exports = {
  connectDB,
  User,
  Category,
  Group,
  Item,
  ChartItem,
}; 