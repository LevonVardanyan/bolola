// Environment variables are provided by PM2 ecosystem.config.js
console.log('🔧 Production Server Environment Check:');
console.log('NODE_ENV:', process.env.NODE_ENV);
console.log('PORT:', process.env.PORT);
console.log('MONGODB_URI:', process.env.MONGODB_URI);
console.log('API_KEY:', process.env.API_KEY ? 'SET' : 'NOT SET');

const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const cors = require('cors');
const { connectDB, User, Category, Group, Item, ChartItem } = require('./models-mongo');
const { promisify } = require('util');

// Firebase Admin SDK
const admin = require('firebase-admin');

// Initialize Firebase Admin (only if service account file exists)
try {
  const serviceAccount = require('./firebase-service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Firebase Admin initialized successfully');
} catch (error) {
  console.log('⚠️  Firebase Admin not initialized:', error.message);
}

// Import SQLite models for migration
const { sequelize, Category: SQLiteCategory, Group: SQLiteGroup, Item: SQLiteItem, ChartItem: SQLiteChartItem } = require('./models');

const app = express();
const PORT = process.env.PORT || 63038;

// API Key for protecting POST endpoints
const API_KEY = process.env.API_KEY || 'your-secret-api-key-2024';

// IP restriction middleware for dangerous endpoints
const restrictToLocalhost = (req, res, next) => {
  const clientIP = req.ip || req.connection.remoteAddress || req.socket.remoteAddress;
  const allowedIPs = ['127.0.0.1', '::1', '::ffff:127.0.0.1', 'localhost'];

  if (!allowedIPs.includes(clientIP)) {
    console.log(`🚨 Blocked dangerous endpoint access from IP: ${clientIP}`);
    return res.status(403).json({
      error: 'Access denied',
      message: 'This endpoint is only accessible from localhost'
    });
  }

  next();
};

// Middleware to protect POST endpoints
const requireApiKey = (req, res, next) => {
  const providedApiKey = req.headers['x-api-key'] || req.query.apikey;

  if (!providedApiKey || providedApiKey !== API_KEY) {
    return res.status(401).json({
      error: 'Unauthorized: Valid API key required',
      message: 'Include API key in X-API-Key header or apikey query parameter'
    });
  }

  next();
};

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Error handling middleware
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).json({ error: 'Invalid JSON format' });
  }
  next();
});

// Serve media files
app.use('/media', express.static(path.join(__dirname, 'media')));

// Serve sources files
app.use('/sources', express.static(path.join(__dirname, 'sources')));

// Dynamic storage path based on category/group/type
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const { category, group, type } = req.body;

    if (!category || !group || !['audios', 'videos'].includes(type)) {
      return cb(new Error('Missing or invalid category/group/type'), null);
    }

    const dir = path.join(__dirname, 'media', category, group, type);
    fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    // Save with original file name only
    cb(null, file.originalname);
  }
});

const upload = multer({
  storage,
  limits: {
    fileSize: 50 * 1024 * 1024 // 50MB limit
  }
});

// Endpoint to get all categories, groups, and items in nested format from MongoDB
app.get('/categories', async (req, res) => {
  try {
    // Fetch all categories
    const categories = await Category.find().sort({ ordering: 1 });

    const result = await Promise.all(categories.map(async (category) => {
      // Fetch groups for this category
      const groups = await Group.find({ categoryAlias: category.alias }).sort({ ordering: 1 });

      const categoryWithGroups = {
        name: category.name,
        alias: category.alias,
        ordering: category.ordering,
        groupNames: category.groupNames,
        groups: await Promise.all(groups.map(async (group) => {
          // Fetch items for this group
          const items = await Item.find({ groupAlias: group.alias }).sort({ ordering: 1 });

          return {
            name: group.name,
            count: group.count,
            iconUrl: group.iconUrl,
            alias: group.alias,
            categoryAlias: group.categoryAlias,
            ordering: group.ordering,
            isNewGroup: group.isNewGroup,
            items: items.map(item => ({
              name: item.name,
              alias: item.alias,
              ordering: item.ordering,
              shareCount: item.shareCount,
              audioUrl: item.audioUrl,
              videoUrl: item.videoUrl,
              imageUrl: item.imageUrl,
              sourceUrl: item.sourceUrl,
              groupAlias: item.groupAlias,
              categoryAlias: item.categoryAlias,
              isFavorite: item.isFavorite,
              keywords: item.keywords,
              relatedKeywords: item.relatedKeywords,
            }))
          };
        }))
      };

      return categoryWithGroups;
    }));

    res.json({ categories: result });
  } catch (error) {
    console.error('Error in /categories:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update a single media item in MongoDB
app.post('/update-media', requireApiKey, async (req, res) => {
  try {
    const item = req.body;
    if (!item || !item.alias) {
      return res.status(400).json({ error: 'Missing item or item.alias' });
    }

    // Find and update the item
    const updatedItem = await Item.findOneAndUpdate(
      { alias: item.alias },
      item,
      { new: true }
    );

    if (!updatedItem) {
      return res.status(404).json({ error: 'Item not found' });
    }

    res.status(200).json({ message: 'Item updated successfully', item: updatedItem });
  } catch (error) {
    console.error('Error in /update-media:', error);
    res.status(500).json({ error: error.message });
  }
});

// Endpoint to save a list of items to the ChartItem collection
app.post('/save-chart', requireApiKey, async (req, res) => {
  try {
    const items = req.body.items;
    if (!Array.isArray(items)) {
      return res.status(400).json({ error: 'Request body must have an items array' });
    }

    for (const item of items) {
      await ChartItem.findOneAndUpdate(
        { alias: item.alias },
        {
          alias: item.alias,
          name: item.name,
          ordering: item.ordering,
          shareCount: item.shareCount,
          audioUrl: item.audioUrl,
          videoUrl: item.videoUrl,
          sourceUrl: item.sourceUrl,
          imageUrl: item.imageUrl,
          isFavorite: item.isFavorite,
          keywords: item.keywords,
          relatedKeywords: item.relatedKeywords,
          groupAlias: item.groupAlias,
          categoryAlias: item.categoryAlias,
        },
        { upsert: true, new: true }
      );
    }

    res.status(200).json({ message: 'Top chart items saved successfully' });
  } catch (error) {
    console.error('Error in /save-chart:', error);
    res.status(500).json({ error: error.message });
  }
});

// Endpoint to update or add a single item in the ChartItem collection
app.post('/update-chart-item', requireApiKey, async (req, res) => {
  try {
    const item = req.body.item;
    if (!item || !item.alias) {
      return res.status(400).json({ error: 'Request body must have an item with alias' });
    }

    const updatedItem = await ChartItem.findOneAndUpdate(
      { alias: item.alias },
      {
        alias: item.alias,
        name: item.name,
        ordering: item.ordering,
        shareCount: item.shareCount,
        audioUrl: item.audioUrl,
        videoUrl: item.videoUrl,
        sourceUrl: item.sourceUrl,
        imageUrl: item.imageUrl,
        isFavorite: item.isFavorite,
        keywords: item.keywords,
        relatedKeywords: item.relatedKeywords,
        groupAlias: item.groupAlias,
        categoryAlias: item.categoryAlias,
      },
      { upsert: true, new: true }
    );

    res.status(200).json({ message: 'Top chart item updated/added successfully', item: updatedItem });
  } catch (error) {
    console.error('Error in /update-chart-item:', error);
    res.status(500).json({ error: error.message });
  }
});

// Endpoint to get all items from the ChartItem collection
app.get('/top-chart', async (req, res) => {
  try {
    const items = await ChartItem.find().sort({ ordering: 1 });
    res.json({ items });
  } catch (error) {
    console.error('Error in /top-chart:', error);
    res.status(500).json({ error: error.message });
  }
});

// ========== USER ENDPOINTS ==========

// Create a new user
app.post('/create-user', requireApiKey, async (req, res) => {
  try {
    const userData = req.body;

    if (!userData.firebaseUid || !userData.name || !userData.email) {
      return res.status(400).json({
        error: 'Missing required fields: firebaseUid, name, email'
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ firebaseUid: userData.firebaseUid });
    if (existingUser) {
      return res.status(409).json({
        error: 'User already exists',
        user: existingUser
      });
    }

    // Create new user
    const newUser = new User({
      firebaseUid: userData.firebaseUid,
      name: userData.name,
      email: userData.email,
      photoUrl: userData.photoUrl || '',
      isAdmin: userData.isAdmin || false,
      isActive: userData.isActive !== undefined ? userData.isActive : true,
      favorites: userData.favorites || [],
      lastLoginAt: new Date()
    });

    const savedUser = await newUser.save();
    res.status(201).json(savedUser);
  } catch (error) {
    console.error('Error in /create-user:', error);
    if (error.code === 11000) {
      // Duplicate key error
      return res.status(409).json({
        error: 'User with this email or Firebase UID already exists'
      });
    }
    res.status(500).json({ error: error.message });
  }
});

// Get user favorites with full item details (MUST come before /user/:firebaseUid)
app.get('/user/favorites', async (req, res) => {
  try {
    const { firebaseUid } = req.query;

    if (!firebaseUid) {
      return res.status(400).json({ error: 'Firebase UID is required' });
    }

    const user = await User.findOne({ firebaseUid }).select('favorites');

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Get full item details for each favorite
    const favoriteItems = await Item.find({
      alias: { $in: user.favorites }
    });

    res.json({
      favorites: user.favorites,
      items: favoriteItems
    });
  } catch (error) {
    console.error('Error in /user/favorites:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get user by Firebase UID
app.get('/user/:firebaseUid', async (req, res) => {
  try {
    const { firebaseUid } = req.params;

    if (!firebaseUid) {
      return res.status(400).json({ error: 'Firebase UID is required' });
    }

    const user = await User.findOne({ firebaseUid });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Update last login time
    user.lastLoginAt = new Date();
    await user.save();

    res.json(user);
  } catch (error) {
    console.error('Error in /user/:firebaseUid:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update user
app.post('/update-user', requireApiKey, async (req, res) => {
  try {
    const userData = req.body;

    if (!userData.firebaseUid) {
      return res.status(400).json({ error: 'Firebase UID is required' });
    }

    const updatedUser = await User.findOneAndUpdate(
      { firebaseUid: userData.firebaseUid },
      {
        $set: {
          name: userData.name,
          email: userData.email,
          photoUrl: userData.photoUrl,
          isAdmin: userData.isAdmin,
          isActive: userData.isActive,
          lastLoginAt: new Date()
        }
      },
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(updatedUser);
  } catch (error) {
    console.error('Error in /update-user:', error);
    res.status(500).json({ error: error.message });
  }
});

// Add item to user favorites
app.post('/user/:firebaseUid/favorites/add', async (req, res) => {
  try {
    const { firebaseUid } = req.params;
    const mediaItem = req.body;

    if (!firebaseUid || !mediaItem || !mediaItem.alias) {
      return res.status(400).json({
        error: 'Firebase UID and MediaItem with alias are required'
      });
    }

    // Check if item exists
    const item = await Item.findOne({ alias: mediaItem.alias });
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }

    const user = await User.findOneAndUpdate(
      { firebaseUid },
      {
        $addToSet: { favorites: mediaItem.alias }, // $addToSet prevents duplicates
        $set: { lastLoginAt: new Date() }
      },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      message: 'Item added to favorites',
      user: user,
      addedItem: mediaItem.alias
    });
  } catch (error) {
    console.error('Error in /user/:firebaseUid/favorites/add:', error);
    res.status(500).json({ error: error.message });
  }
});

// Remove item from user favorites
app.post('/user/:firebaseUid/favorites/remove', async (req, res) => {
  try {
    const { firebaseUid } = req.params;
    const mediaItem = req.body;

    if (!firebaseUid || !mediaItem || !mediaItem.alias) {
      return res.status(400).json({
        error: 'Firebase UID and MediaItem with alias are required'
      });
    }

    const user = await User.findOneAndUpdate(
      { firebaseUid },
      {
        $pull: { favorites: mediaItem.alias }, // $pull removes the item
        $set: { lastLoginAt: new Date() }
      },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      message: 'Item removed from favorites',
      user: user,
      removedItem: mediaItem.alias
    });
  } catch (error) {
    console.error('Error in /user/:firebaseUid/favorites/remove:', error);
    res.status(500).json({ error: error.message });
  }
});



// Get all users
app.get('/users', async (req, res) => {
  try {
    const users = await User.find().sort({ createdAt: -1 });

    res.json({
      users: users,
      count: users.length
    });
  } catch (error) {
    console.error('Error in /users:', error);
    res.status(500).json({ error: error.message });
  }
});

// ========== END USER ENDPOINTS ==========

// ========== FCM NOTIFICATION ENDPOINTS ==========

// Send Firebase Cloud Messaging notification to topic
app.post('/send-notification', requireApiKey, async (req, res) => {
  try {
    const { topic, title, message, data } = req.body;

    // Validation
    if (!topic || !title || !message) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['topic', 'title', 'message'],
        received: { topic: !!topic, title: !!title, message: !!message }
      });
    }

    // Check if Firebase Admin is initialized
    if (!admin.apps.length) {
      return res.status(500).json({
        error: 'Firebase Admin not initialized',
        message: 'Firebase service account not configured'
      });
    }

    // Prepare notification payload
    const payload = {
      notification: {
        title: title,
        body: message
      },
      topic: topic
    };

    // Add optional data payload
    if (data && typeof data === 'object') {
      payload.data = {};
      // Convert all data values to strings (FCM requirement)
      for (const [key, value] of Object.entries(data)) {
        payload.data[key] = String(value);
      }
    }

    console.log('📱 Sending FCM notification to topic:', { title, message, topic });

    // Send notification to topic
    const response = await admin.messaging().send(payload);

    console.log('✅ FCM notification sent successfully to topic:', response);

    res.status(200).json({
      success: true,
      message: 'Notification sent successfully to topic',
      messageId: response,
      sentToTopic: topic,
      payload: {
        title,
        message,
        data: data || null
      }
    });

  } catch (error) {
    console.error('❌ Error sending FCM notification to topic:', error);

    // Handle specific FCM errors
    let errorMessage = error.message;
    let statusCode = 500;

    if (error.code === 'messaging/invalid-topic-name') {
      errorMessage = 'Invalid topic name';
      statusCode = 400;
    } else if (error.code === 'messaging/topic-name-invalid') {
      errorMessage = 'Topic name format is invalid';
      statusCode = 400;
    } else if (error.code === 'messaging/invalid-argument') {
      errorMessage = 'Invalid notification payload';
      statusCode = 400;
    }

    res.status(statusCode).json({
      error: 'Failed to send notification to topic',
      message: errorMessage,
      code: error.code || 'unknown'
    });
  }
});

// ========== END FCM NOTIFICATION ENDPOINTS ==========

// Migration endpoint to convert SQLite data to MongoDB
// app.post('/migrate-sqlite-to-mongo', restrictToLocalhost, requireApiKey, async (req, res) => {
//   try {
//     // Safety confirmation required

//     console.log('Starting SQLite to MongoDB migration...');

//     // Ensure SQLite database is synced
//     await sequelize.sync();

//     // Clear all MongoDB collections before migration
//     console.log('🗑️  Clearing MongoDB collections...');
//     await Category.deleteMany({});
//     await Group.deleteMany({});
//     await Item.deleteMany({});
//     await ChartItem.deleteMany({});
//     console.log('✅ All collections cleared');

//     // Migrate Categories
//     const sqliteCategories = await SQLiteCategory.findAll();
//     let categoriesCount = 0;
//     for (const cat of sqliteCategories) {
//       await Category.findOneAndUpdate(
//         { alias: cat.alias },
//         {
//           alias: cat.alias,
//           name: cat.name,
//           ordering: cat.ordering,
//           groupNames: cat.groupNames,
//         },
//         { upsert: true, new: true }
//       );
//       categoriesCount++;
//     }

//     // Migrate Groups
//     const sqliteGroups = await SQLiteGroup.findAll();
//     let groupsCount = 0;
//     for (const grp of sqliteGroups) {
//       // Construct iconUrl from CDN thumbnails folder
//       const iconUrl = `https://cdn.bolola.org/thumbnails/${grp.alias}.jpg`;

//       await Group.findOneAndUpdate(
//         { alias: grp.alias },
//         {
//           alias: grp.alias,
//           name: grp.name,
//           count: grp.count,
//           iconUrl: iconUrl, // Constructed CDN iconUrl
//           ordering: grp.ordering,
//           isNewGroup: grp.isNew,
//           categoryAlias: grp.categoryAlias,
//         },
//         { upsert: true, new: true }
//       );
//       groupsCount++;
//     }

//     // Migrate Items
//     const sqliteItems = await SQLiteItem.findAll();
//     let itemsCount = 0;
//     for (const item of sqliteItems) {
//       // Construct imageUrl from CDN - video items use video_thumbnails folder, others use regular structure
//       let imageUrl = `https://cdn.bolola.org/video_thumbnails/${item.categoryAlias}/${item.groupAlias}/${item.alias}.jpg`;

//       await Item.findOneAndUpdate(
//         { alias: item.alias },
//         {
//           alias: item.alias,
//           name: item.name,
//           ordering: item.ordering,
//           shareCount: item.shareCount,
//           audioUrl: item.audioUrl,
//           videoUrl: item.videoUrl,
//           sourceUrl: item.sourceUrl,
//           imageUrl: imageUrl, // Constructed CDN imageUrl
//           isFavorite: item.isFavorite,
//           keywords: item.keywords,
//           relatedKeywords: item.relatedKeywords,
//           groupAlias: item.groupAlias,
//           categoryAlias: item.categoryAlias,
//         },
//         { upsert: true, new: true }
//       );
//       itemsCount++;
//     }

//     // Migrate Chart Items
//     const sqliteChartItems = await SQLiteChartItem.findAll();
//     let chartItemsCount = 0;
//     for (const chartItem of sqliteChartItems) {
//       // Construct imageUrl from CDN - video items use video_thumbnails folder, others use regular structure
//       let imageUrl = `https://cdn.bolola.org/video_thumbnails/${chartItem.categoryAlias}/${chartItem.groupAlias}/${chartItem.alias}.jpg`;


//       await ChartItem.findOneAndUpdate(
//         { alias: chartItem.alias },
//         {
//           alias: chartItem.alias,
//           name: chartItem.name,
//           ordering: chartItem.ordering,
//           shareCount: chartItem.shareCount,
//           audioUrl: chartItem.audioUrl,
//           videoUrl: chartItem.videoUrl,
//           sourceUrl: chartItem.sourceUrl,
//           imageUrl: imageUrl, // Constructed CDN imageUrl
//           isFavorite: chartItem.isFavorite,
//           keywords: chartItem.keywords,
//           relatedKeywords: chartItem.relatedKeywords,
//           groupAlias: chartItem.groupAlias,
//           categoryAlias: chartItem.categoryAlias,
//         },
//         { upsert: true, new: true }
//       );
//       chartItemsCount++;
//     }

//     console.log(`Migration completed successfully:`);
//     console.log(`- Categories: ${categoriesCount}`);
//     console.log(`- Groups: ${groupsCount}`);
//     console.log(`- Items: ${itemsCount}`);
//     console.log(`- Chart Items: ${chartItemsCount}`);

//     res.status(200).json({
//       message: 'SQLite to MongoDB migration completed successfully',
//       migrated: {
//         categories: categoriesCount,
//         groups: groupsCount,
//         items: itemsCount,
//         chartItems: chartItemsCount
//       }
//     });
//   } catch (error) {
//     console.error('Error in migration:', error);
//     res.status(500).json({ error: error.message });
//   }
// });











// Database migration endpoint
app.post('/migrate-db', requireApiKey, async (req, res) => {
  try {
    const { email } = req.body;

    // Check if email is provided
    if (!email) {
      return res.status(400).json({
        error: 'Email parameter is required',
        message: 'Only admin users can perform database migration'
      });
    }

    // Check if user exists and is admin
    const adminUser = await User.findOne({ email, isAdmin: true });
    if (!adminUser) {
      return res.status(403).json({
        error: 'Access denied',
        message: 'Only admin users can perform database migration'
      });
    }

    console.log(`🚀 Starting database migration from production to staging... (initiated by admin: ${email})`);

    // This is the production server, so we migrate FROM production TO staging
    const productionUri = 'mongodb://localhost:27017/bolola-production';
    const stagingUri = 'mongodb://localhost:27017/bolola-staging';

    console.log(`📤 Source (production): ${productionUri}`);
    console.log(`📥 Target (staging): ${stagingUri}`);

    // Create separate connections for migration
    const mongoose = require('mongoose');

    // Source connection (production)
    const sourceConnection = mongoose.createConnection(productionUri);
    await sourceConnection.asPromise();

    // Target connection (staging)
    const targetConnection = mongoose.createConnection(stagingUri);
    await targetConnection.asPromise();

    // Create models for both connections using the same schemas
    const createModels = (connection) => ({
      Category: connection.model('Category', Category.schema),
      Group: connection.model('Group', Group.schema),
      Item: connection.model('Item', Item.schema),
      ChartItem: connection.model('ChartItem', ChartItem.schema),
      User: connection.model('User', User.schema)
    });

    const sourceModels = createModels(sourceConnection);
    const targetModels = createModels(targetConnection);

    // Get initial counts
    const getCollectionCounts = async (models) => {
      const counts = {};
      for (const [name, model] of Object.entries(models)) {
        counts[name] = await model.countDocuments();
      }
      return counts;
    };

    const sourceCounts = await getCollectionCounts(sourceModels);
    const initialTargetCounts = await getCollectionCounts(targetModels);

    console.log('📊 Initial counts:');
    console.log('Source (production):', sourceCounts);
    console.log('Target (staging):', initialTargetCounts);

    // Migration function
    const migrateCollection = async (sourceModel, targetModel, collectionName) => {
      console.log(`\n📦 Migrating ${collectionName}...`);

      const documents = await sourceModel.find({}).lean();
      console.log(`   Found ${documents.length} documents in production`);

      if (documents.length === 0) {
        console.log(`   ✅ No documents to migrate`);
        return { migrated: 0, errors: 0 };
      }

      // Clear target collection first
      const deleteResult = await targetModel.deleteMany({});
      console.log(`   🗑️  Cleared ${deleteResult.deletedCount} documents from staging`);

      let migrated = 0;
      let errors = 0;

      // Insert documents in batches
      const batchSize = 100;
      for (let i = 0; i < documents.length; i += batchSize) {
        const batch = documents.slice(i, i + batchSize);

        try {
          // Remove MongoDB-specific fields that might cause issues
          const cleanBatch = batch.map(doc => {
            const { _id, __v, ...cleanDoc } = doc;
            return cleanDoc;
          });

          await targetModel.insertMany(cleanBatch, { ordered: false });
          migrated += batch.length;
          console.log(`   ⏳ Migrated ${migrated}/${documents.length} documents`);
        } catch (error) {
          console.error(`   ❌ Error migrating batch: ${error.message}`);
          errors += batch.length;
        }
      }

      console.log(`   ✅ ${collectionName} migration complete: ${migrated} migrated, ${errors} errors`);
      return { migrated, errors };
    };

    // Migrate collections in dependency order
    const migrationOrder = ['User', 'Category', 'Group', 'Item', 'ChartItem'];
    const results = {};
    let totalMigrated = 0;
    let totalErrors = 0;

    for (const collectionName of migrationOrder) {
      if (sourceModels[collectionName] && targetModels[collectionName]) {
        const result = await migrateCollection(
          sourceModels[collectionName],
          targetModels[collectionName],
          collectionName
        );
        results[collectionName] = result;
        totalMigrated += result.migrated;
        totalErrors += result.errors;
      }
    }

    // Get final counts
    const finalTargetCounts = await getCollectionCounts(targetModels);
    console.log('\n📊 Final staging counts:', finalTargetCounts);

    // Close connections
    await sourceConnection.close();
    await targetConnection.close();

    console.log('🎉 Migration completed successfully!');

    res.status(200).json({
      message: 'Database migration completed successfully',
      direction: 'production → staging',
      summary: {
        totalMigrated,
        totalErrors,
        collections: results
      },
      counts: {
        source: sourceCounts,
        targetBefore: initialTargetCounts,
        targetAfter: finalTargetCounts
      }
    });

  } catch (error) {
    console.error('❌ Migration failed:', error);
    res.status(500).json({
      error: 'Database migration failed',
      details: error.message,
      direction: 'production → staging'
    });
  }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`MongoDB-based production server running at http://0.0.0.0:${PORT}`);
}); 