const Channel = require("../models/Channel");
const User = require("../models/User");
const Message = require("../models/Message");
const { validationResult } = require("express-validator");

// @desc    Create a new channel
// @route   POST /api/channels
// @access  Private
exports.createChannel = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { name, description } = req.body;

  try {
    // Check if channel name already exists
    let channel = await Channel.findOne({ name });
    if (channel) {
      return res.status(400).json({ msg: "Channel name already taken" });
    }

    // Create new channel
    channel = new Channel({
      name,
      description,
      owner: req.user.id, // Owner is the logged-in user
      members: [req.user.id], // Owner is automatically a member
    });

    await channel.save();

    res.status(201).json(channel);
  } catch (err) {
    console.error("Create channel error:", err.message);
    res.status(500).send("Server error");
  }
};

// @desc    Get all channels
// @route   GET /api/channels
// @access  Private
exports.getAllChannels = async (req, res) => {
  try {
    // Find all channels, potentially add pagination later
    const channels = await Channel.find().populate("owner", "username"); // Populate owner username
    res.json(channels);
  } catch (err) {
    console.error("Get all channels error:", err.message);
    res.status(500).send("Server error");
  }
};

// @desc    Get channel details by ID
// @route   GET /api/channels/:id
// @access  Private
exports.getChannelById = async (req, res) => {
  try {
    const channel = await Channel.findById(req.params.id)
      .populate("owner", "username email") // Populate owner details
      .populate("members", "username"); // Populate member usernames

    if (!channel) {
      return res.status(404).json({ msg: "Channel not found" });
    }

    // Optional: Check if the requesting user is a member before returning details
    // if (!channel.members.some(member => member._id.equals(req.user.id))) {
    //   return res.status(403).json({ msg: "Not authorized to view this channel" });
    // }

    res.json(channel);
  } catch (err) {
    console.error("Get channel by ID error:", err.message);
    if (err.kind === "ObjectId") {
      return res.status(404).json({ msg: "Channel not found" });
    }
    res.status(500).send("Server error");
  }
};

// @desc    Join a channel
// @route   POST /api/channels/:id/join
// @access  Private
exports.joinChannel = async (req, res) => {
  try {
    const channel = await Channel.findById(req.params.id);

    if (!channel) {
      return res.status(404).json({ msg: "Channel not found" });
    }

    // Check if user is already a member
    if (channel.members.includes(req.user.id)) {
      return res.status(400).json({ msg: "User already in this channel" });
    }

    // Add user to members list
    channel.members.push(req.user.id);
    await channel.save();

    // Optionally, emit an event via Socket.IO to notify other members

    res.json({ msg: "Successfully joined channel", members: channel.members });
  } catch (err) {
    console.error("Join channel error:", err.message);
    if (err.kind === "ObjectId") {
      return res.status(404).json({ msg: "Channel not found" });
    }
    res.status(500).send("Server error");
  }
};

// @desc    Leave a channel
// @route   POST /api/channels/:id/leave
// @access  Private
exports.leaveChannel = async (req, res) => {
  try {
    const channel = await Channel.findById(req.params.id);

    if (!channel) {
      return res.status(404).json({ msg: "Channel not found" });
    }

    // Check if user is a member
    if (!channel.members.includes(req.user.id)) {
      return res.status(400).json({ msg: "User not in this channel" });
    }

    // Prevent owner from leaving? Or handle ownership transfer?
    // For now, let's allow leaving, but consider implications.
    // if (channel.owner.equals(req.user.id)) {
    //   return res.status(400).json({ msg: "Owner cannot leave the channel directly. Delete or transfer ownership." });
    // }

    // Remove user from members list
    channel.members = channel.members.filter(
      (memberId) => !memberId.equals(req.user.id)
    );

    // Optional: If channel becomes empty, delete it?
    // if (channel.members.length === 0) {
    //   await Channel.findByIdAndDelete(req.params.id);
    //   return res.json({ msg: "Successfully left channel and channel deleted" });
    // }

    await channel.save();

    // Optionally, emit an event via Socket.IO to notify other members

    res.json({ msg: "Successfully left channel", members: channel.members });
  } catch (err) {
    console.error("Leave channel error:", err.message);
    if (err.kind === "ObjectId") {
      return res.status(404).json({ msg: "Channel not found" });
    }
    res.status(500).send("Server error");
  }
};

// @desc    Get messages for a channel
// @route   GET /api/channels/:id/messages
// @access  Private (Member only)
exports.getChannelMessages = async (req, res) => {
  try {
    const channel = await Channel.findById(req.params.id);
    if (!channel) {
      return res.status(404).json({ msg: "Channel not found" });
    }

    // Ensure the requesting user is a member of the channel
    if (!channel.members.some(memberId => memberId.equals(req.user.id))) {
       return res.status(403).json({ msg: "Not authorized to view messages for this channel" });
    }

    // Fetch messages, sort by timestamp, potentially add pagination
    const messages = await Message.find({ channel: req.params.id })
      .populate("sender", "username") // Populate sender's username
      .sort({ timestamp: 1 }); // Sort oldest first

    res.json(messages);
  } catch (err) {
    console.error("Get channel messages error:", err.message);
    if (err.kind === "ObjectId") {
      return res.status(404).json({ msg: "Channel not found" });
    }
    res.status(500).send("Server error");
  }
};

// Note: Sending messages will be handled primarily via Socket.IO for real-time updates,
// but the getChannelMessages endpoint provides history retrieval.
