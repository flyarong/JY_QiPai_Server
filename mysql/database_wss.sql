/*
 Navicat Premium Data Transfer

 Source Server         : test_server
 Source Server Type    : MySQL
 Source Server Version : 50721
 Source Host           : 192.168.0.203:23456
 Source Schema         : wss_test

 Target Server Type    : MySQL
 Target Server Version : 50721
 File Encoding         : 65001

 Date: 10/01/2019 19:48:18
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for activity_cumulate_data
-- ----------------------------
DROP TABLE IF EXISTS `activity_cumulate_data`;
CREATE TABLE `activity_cumulate_data`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '玩家id',
  `game_id` mediumint(20) NULL DEFAULT NULL COMMENT '自由场id',
  `progress` mediumint(20) NULL DEFAULT NULL COMMENT '进度',
  `time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for admin_decrease_asset_log
-- ----------------------------
DROP TABLE IF EXISTS `admin_decrease_asset_log`;
CREATE TABLE `admin_decrease_asset_log`  (
  `log_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志 id ，主键',
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `asset_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '财物类型： match_ticket, room_card,shop_gold,cash',
  `change_value` bigint(20) NULL DEFAULT NULL COMMENT '变化量',
  `current` bigint(20) NULL DEFAULT NULL COMMENT '变化后数量',
  `date` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP,
  `opt_admin` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '操作人',
  `reason` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '原因',
  PRIMARY KEY (`log_id`) USING BTREE,
  INDEX `index2`(`asset_type`) USING BTREE,
  INDEX `index3`(`opt_admin`) USING BTREE,
  INDEX `index4`(`reason`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家财物日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for admin_op_log
-- ----------------------------
DROP TABLE IF EXISTS `admin_op_log`;
CREATE TABLE `admin_op_log`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '管理员id',
  `op_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `player_id1` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '被操作的相关玩家1',
  `player_id2` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '被操作的相关玩家2',
  `op_data1` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '操作的数据1',
  `op_data2` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '操作的数据2',
  `op_data3` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '操作的数据3',
  `time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '管理员操作日志' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for bind_phone_number
-- ----------------------------
DROP TABLE IF EXISTS `bind_phone_number`;
CREATE TABLE `bind_phone_number`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `phone_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `bind_time` datetime(0) NULL DEFAULT NULL,
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for bind_phone_number_opt_log
-- ----------------------------
DROP TABLE IF EXISTS `bind_phone_number_opt_log`;
CREATE TABLE `bind_phone_number_opt_log`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `old_phone_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `new_phone_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `opt_time` datetime(0) NULL DEFAULT NULL,
  `opt_admin` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for dwq_cdkey
-- ----------------------------
DROP TABLE IF EXISTS `dwq_cdkey`;
CREATE TABLE `dwq_cdkey`  (
  `no` bigint(20) NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `asset_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `cdkey` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `time` datetime(0) NULL DEFAULT NULL,
  PRIMARY KEY (`no`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for dwq_cdkey_use_log
-- ----------------------------
DROP TABLE IF EXISTS `dwq_cdkey_use_log`;
CREATE TABLE `dwq_cdkey_use_log`  (
  `no` bigint(20) NULL DEFAULT NULL,
  `use_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `owner_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `asset_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `cdkey` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `use_type` int(11) NULL DEFAULT NULL,
  `use_time` datetime(0) NULL DEFAULT NULL,
  `create_time` datetime(0) NULL DEFAULT NULL
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for dwq_use_log
-- ----------------------------
DROP TABLE IF EXISTS `dwq_use_log`;
CREATE TABLE `dwq_use_log`  (
  `no` bigint(20) NULL DEFAULT NULL,
  `use_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `owner_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `asset_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `cdkey` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `use_type` int(11) NULL DEFAULT NULL,
  `use_time` datetime(0) NULL DEFAULT NULL,
  `create_time` datetime(0) NULL DEFAULT NULL
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for emails
-- ----------------------------
DROP TABLE IF EXISTS `emails`;
CREATE TABLE `emails`  (
  `id` int(50) UNSIGNED NOT NULL,
  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '',
  `title` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '',
  `sender` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `receiver` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `state` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `valid_time` bigint(20) NULL DEFAULT NULL,
  `data` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `create_time` bigint(20) NULL DEFAULT NULL,
  `complete_time` bigint(20) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for emails_admin_opt_log
-- ----------------------------
DROP TABLE IF EXISTS `emails_admin_opt_log`;
CREATE TABLE `emails_admin_opt_log`  (
  `id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '玩家id\n\n10111111111，ID由11位数字组成，前两位表示服务器号',
  `data` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '',
  `time` datetime(6) NULL DEFAULT NULL,
  `opt_admin` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '创建邮件的管理员',
  `reason` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_latvian_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for emails_log
-- ----------------------------
DROP TABLE IF EXISTS `emails_log`;
CREATE TABLE `emails_log`  (
  `id` int(50) NOT NULL,
  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '',
  `title` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '',
  `sender` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `receiver` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `state` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `valid_time` datetime(6) NULL DEFAULT NULL,
  `data` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `create_time` datetime(6) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for emails_opt_log
-- ----------------------------
DROP TABLE IF EXISTS `emails_opt_log`;
CREATE TABLE `emails_opt_log`  (
  `id` int(50) UNSIGNED NOT NULL AUTO_INCREMENT,
  `email_id` int(255) NULL DEFAULT NULL,
  `opt` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '',
  `time` datetime(6) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1390 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for freestyle_nmjxl_race_log
-- ----------------------------
DROP TABLE IF EXISTS `freestyle_nmjxl_race_log`;
CREATE TABLE `freestyle_nmjxl_race_log`  (
  `id` int(10) UNSIGNED NOT NULL COMMENT '对局id，自增长主键',
  `game_id` int(11) NULL DEFAULT NULL,
  `game_model` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `begin_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` datetime(0) NULL DEFAULT NULL COMMENT '结束时间',
  `gang_count` int(10) NULL DEFAULT 0 COMMENT '杠数量',
  `geng_count` int(10) NULL DEFAULT 0 COMMENT '根',
  `base_score` int(10) NULL DEFAULT 0 COMMENT '底分',
  `operation_list` varbinary(1024) NULL DEFAULT 0 COMMENT '操作序列',
  `zhuang_seat` int(10) NULL DEFAULT 0 COMMENT '庄座位号',
  `seat1_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat2_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat3_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat4_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for freestyle_nmjxl_race_player_log
-- ----------------------------
DROP TABLE IF EXISTS `freestyle_nmjxl_race_player_log`;
CREATE TABLE `freestyle_nmjxl_race_player_log`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '对局id，自增长主键',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `race_id` int(11) NULL DEFAULT NULL,
  `seat` int(10) NULL DEFAULT 0 COMMENT '座位号',
  `score` int(10) NULL DEFAULT 0 COMMENT '得分',
  `multi` int(10) NULL DEFAULT 0 COMMENT '倍数',
  `gang_info` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0',
  `pai_info` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for freestyle_race_log
-- ----------------------------
DROP TABLE IF EXISTS `freestyle_race_log`;
CREATE TABLE `freestyle_race_log`  (
  `id` int(10) UNSIGNED NOT NULL COMMENT '比赛实例唯一id',
  `game_id` int(10) UNSIGNED NULL DEFAULT 0 COMMENT '比赛唯一id',
  `name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `game_type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `begin_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` datetime(0) NULL DEFAULT NULL COMMENT '结束时间',
  `player_count` int(10) UNSIGNED NULL DEFAULT 0 COMMENT '参赛人数',
  `races` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '比赛场次日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for freestyle_race_player_log
-- ----------------------------
DROP TABLE IF EXISTS `freestyle_race_player_log`;
CREATE TABLE `freestyle_race_player_log`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增长主键',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `match_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '比赛实例唯一id',
  `score` bigint(10) NULL DEFAULT 0 COMMENT '成绩',
  `real_score` int(10) NULL DEFAULT 0 COMMENT '真实',
  `room_rent` int(10) NULL DEFAULT 0 COMMENT '真实',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 33 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家比赛日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for freestyle_tyddz_race_log
-- ----------------------------
DROP TABLE IF EXISTS `freestyle_tyddz_race_log`;
CREATE TABLE `freestyle_tyddz_race_log`  (
  `id` int(10) UNSIGNED NOT NULL COMMENT '对局id，自增长主键',
  `game_id` int(10) NULL DEFAULT NULL,
  `begin_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` datetime(0) NULL DEFAULT NULL COMMENT '结束时间',
  `bomb_count` int(10) NULL DEFAULT 0 COMMENT '炸弹数量',
  `spring` int(10) NULL DEFAULT 0 COMMENT '春天（0 无，1春天，2 反春）',
  `base_score` int(10) NULL DEFAULT 0 COMMENT '底分',
  `base_rate` int(10) NULL DEFAULT 0 COMMENT '底倍',
  `operation_list` varbinary(500) NULL DEFAULT 0 COMMENT '操作序列',
  `dizhu_seat` int(10) NULL DEFAULT 0 COMMENT '地主座位号',
  `seat1_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat2_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat3_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `game_model` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for freestyle_tyddz_race_player_log
-- ----------------------------
DROP TABLE IF EXISTS `freestyle_tyddz_race_player_log`;
CREATE TABLE `freestyle_tyddz_race_player_log`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '对局id，自增长主键',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `race_id` int(11) NULL DEFAULT NULL,
  `seat` int(10) NULL DEFAULT 0 COMMENT '座位号',
  `score` int(10) NULL DEFAULT 0 COMMENT '得分',
  `rate` int(10) NULL DEFAULT 0 COMMENT '倍数',
  `bomb_count` int(10) NULL DEFAULT 0 COMMENT '炸弹数（自己的炸弹）',
  `spring` int(10) NULL DEFAULT 0 COMMENT '春天（0 无，1春天，2 反春，3 被春天，4被反春）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for friendgame_history_record
-- ----------------------------
DROP TABLE IF EXISTS `friendgame_history_record`;
CREATE TABLE `friendgame_history_record`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '对局id，自增长主键',
  `game_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `time` bigint(20) NULL DEFAULT 0 COMMENT '得分',
  `room_no` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p1_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p1_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p1_head_img_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p1_score` int(20) NULL DEFAULT NULL,
  `p2_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p2_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p2_head_img_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p2_score` int(20) NULL DEFAULT NULL,
  `p3_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p3_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p3_head_img_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p3_score` int(20) NULL DEFAULT NULL,
  `p4_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p4_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p4_head_img_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `p4_score` int(20) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE,
  INDEX `time`(`time`) USING BTREE,
  INDEX `p1_id`(`p1_id`) USING BTREE,
  INDEX `p2_id`(`p2_id`) USING BTREE,
  INDEX `p3_id`(`p3_id`) USING BTREE,
  INDEX `p4_id`(`p4_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for friendgame_player_history
-- ----------------------------
DROP TABLE IF EXISTS `friendgame_player_history`;
CREATE TABLE `friendgame_player_history`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `records` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for friendgame_room_log
-- ----------------------------
DROP TABLE IF EXISTS `friendgame_room_log`;
CREATE TABLE `friendgame_room_log`  (
  `id` int(10) UNSIGNED NOT NULL COMMENT '对局id，自增长主键',
  `game_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `room_no` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '得分',
  `room_owner` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '房主',
  `room_rent` int(255) NULL DEFAULT NULL COMMENT '房费',
  `room_options` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `begin_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` datetime(0) NULL DEFAULT NULL COMMENT '结束时间',
  `over_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for friendgame_room_race_log
-- ----------------------------
DROP TABLE IF EXISTS `friendgame_room_race_log`;
CREATE TABLE `friendgame_room_race_log`  (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增长id',
  `room_id` int(11) NULL DEFAULT NULL COMMENT '房间id',
  `race_id` int(11) NULL DEFAULT NULL COMMENT '对局id',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `room_id`(`room_id`) USING BTREE,
  INDEX `race_id`(`race_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '房间对局日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for game_profit
-- ----------------------------
DROP TABLE IF EXISTS `game_profit`;
CREATE TABLE `game_profit`  (
  `game_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '游戏id,matchstyle_xx ; freestyle_xx',
  `total_profit` bigint(50) NULL DEFAULT NULL COMMENT '总共我方收益；(玩家的付出)',
  `total_loss` bigint(50) NULL DEFAULT NULL COMMENT '总共我方付出；(玩家的收益)',
  `total_profit_loss` int(50) NULL DEFAULT NULL COMMENT '总共付出or收益',
  `last_record_time` bigint(50) NULL DEFAULT NULL COMMENT '上一次记录的时间',
  `month_profit` bigint(50) NULL DEFAULT NULL COMMENT '当月收益',
  `month_loss` bigint(50) NULL DEFAULT NULL COMMENT '当月付出',
  `month_profit_loss` int(50) NULL DEFAULT NULL COMMENT '当月收益or付出',
  PRIMARY KEY (`game_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for game_profit_statistics
-- ----------------------------
DROP TABLE IF EXISTS `game_profit_statistics`;
CREATE TABLE `game_profit_statistics`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `game_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '游戏id,matchstyle_xx ; freestyle_xx',
  `profit` bigint(50) NULL DEFAULT NULL COMMENT '我方收益',
  `loss` bigint(50) NULL DEFAULT NULL COMMENT '我方付出',
  `profit_loss` int(50) NULL DEFAULT NULL COMMENT '收益or付出',
  `record_time` bigint(50) NULL DEFAULT NULL COMMENT '记录的时间',
  `record_year` mediumint(20) NULL DEFAULT NULL COMMENT '记录时的年份',
  `record_month` tinyint(10) NULL DEFAULT NULL COMMENT '记录时的月份',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for gift_bag_data
-- ----------------------------
DROP TABLE IF EXISTS `gift_bag_data`;
CREATE TABLE `gift_bag_data`  (
  `gift_bag_id` tinyint(4) NOT NULL,
  `gift_bag_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `count` int(20) NULL DEFAULT 0,
  PRIMARY KEY (`gift_bag_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家财物表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for goods_exchange_log
-- ----------------------------
DROP TABLE IF EXISTS `goods_exchange_log`;
CREATE TABLE `goods_exchange_log`  (
  `id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '日志唯一 id 号',
  `exchange_type` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '兑换类型：jing_bi, jipaiqi',
  `config_id` int(11) NOT NULL COMMENT '配置id，shoping_config 配置表中的 id 列',
  `diamond` bigint(20) NOT NULL COMMENT '消耗的钻石数量',
  `goods_value` bigint(20) NOT NULL COMMENT '买到的物品数量： 鲸币数量，记牌器小时数',
  `gift_asset` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '赠送的财富： json 数据',
  `time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '充值界面中 用代币（钻石）购买其他物品：鲸币、记牌器' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for load_and_close_ser_cfg
-- ----------------------------
DROP TABLE IF EXISTS `load_and_close_ser_cfg`;
CREATE TABLE `load_and_close_ser_cfg`  (
  `id` int(11) NOT NULL,
  `path` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `startTime` datetime(0) NULL DEFAULT NULL,
  `closeTime` datetime(0) NULL DEFAULT NULL,
  `isover` int(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for match_nor_log
-- ----------------------------
DROP TABLE IF EXISTS `match_nor_log`;
CREATE TABLE `match_nor_log`  (
  `id` int(10) UNSIGNED NOT NULL COMMENT '比赛实例唯一id',
  `game_id` int(10) UNSIGNED NULL DEFAULT 0 COMMENT '比赛唯一id',
  `name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `game_type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `begin_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` datetime(0) NULL DEFAULT NULL COMMENT '结束时间',
  `player_count` int(10) UNSIGNED NULL DEFAULT 0 COMMENT '参赛人数',
  `races` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '比赛场次日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for match_nor_player_log
-- ----------------------------
DROP TABLE IF EXISTS `match_nor_player_log`;
CREATE TABLE `match_nor_player_log`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增长主键',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `match_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '比赛实例唯一id',
  `score` int(10) NULL DEFAULT 0 COMMENT '成绩',
  `rank` int(10) NULL DEFAULT 0 COMMENT '名次',
  `award` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '奖励（json 字符串）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家比赛日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for million_ddz_bonus_week
-- ----------------------------
DROP TABLE IF EXISTS `million_ddz_bonus_week`;
CREATE TABLE `million_ddz_bonus_week`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '玩家id',
  `bonus` int(10) UNSIGNED NULL DEFAULT 0 COMMENT '比赛唯一id',
  PRIMARY KEY (`player_id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`player_id`) USING BTREE,
  INDEX `rank`(`bonus`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '比赛场次日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for million_ddz_log
-- ----------------------------
DROP TABLE IF EXISTS `million_ddz_log`;
CREATE TABLE `million_ddz_log`  (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '比赛实例唯一id',
  `game_id` int(10) UNSIGNED NULL DEFAULT 0 COMMENT '比赛唯一id',
  `issue` int(10) UNSIGNED NULL DEFAULT 0 COMMENT '比赛场次序号',
  `player_count` int(10) UNSIGNED NULL DEFAULT 0 COMMENT '参赛人数',
  `begin_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` datetime(0) NULL DEFAULT NULL COMMENT '结束时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '比赛场次日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for million_ddz_player_log
-- ----------------------------
DROP TABLE IF EXISTS `million_ddz_player_log`;
CREATE TABLE `million_ddz_player_log`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增长主键',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `game_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '比赛实例唯一id',
  `issue` int(11) NULL DEFAULT NULL,
  `score` int(10) NULL DEFAULT 0 COMMENT '成绩',
  `final_round` int(11) NULL DEFAULT NULL,
  `final_win` int(11) NULL DEFAULT NULL,
  `award` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '奖励（json 字符串）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家比赛日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for million_ddz_race_log
-- ----------------------------
DROP TABLE IF EXISTS `million_ddz_race_log`;
CREATE TABLE `million_ddz_race_log`  (
  `id` int(10) UNSIGNED NOT NULL COMMENT '对局id，自增长主键',
  `game_id` int(100) NULL DEFAULT 0 COMMENT '比赛实例id',
  `issue` int(11) NULL DEFAULT NULL,
  `round` int(10) NULL DEFAULT 0 COMMENT '轮序号',
  `race` int(10) NULL DEFAULT 0 COMMENT '局序号',
  `begin_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` datetime(0) NULL DEFAULT NULL COMMENT '结束时间',
  `bomb_count` int(10) NULL DEFAULT 0 COMMENT '炸弹数量',
  `spring` int(10) NULL DEFAULT 0 COMMENT '春天（0 无，1春天，2 反春）',
  `base_score` int(10) NULL DEFAULT 0 COMMENT '底分',
  `base_rate` int(10) NULL DEFAULT 0 COMMENT '底倍',
  `operation_list` varbinary(500) NULL DEFAULT 0 COMMENT '操作序列',
  `dizhu_seat` int(10) NULL DEFAULT 0 COMMENT '地主座位号',
  `seat1_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat2_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat3_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '对局日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for million_ddz_race_player_log
-- ----------------------------
DROP TABLE IF EXISTS `million_ddz_race_player_log`;
CREATE TABLE `million_ddz_race_player_log`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '对局id，自增长主键',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `race_id` int(10) NULL DEFAULT 0 COMMENT '对局id',
  `seat` int(10) NULL DEFAULT 0 COMMENT '座位号',
  `score` int(10) NULL DEFAULT 0 COMMENT '得分',
  `rate` int(10) NULL DEFAULT 0 COMMENT '倍数',
  `bomb_count` int(10) NULL DEFAULT 0 COMMENT '炸弹数（自己的炸弹）',
  `spring` int(10) NULL DEFAULT 0 COMMENT '春天（0 无，1春天，2 反春，3 被春天，4被反春）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家对局日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for million_ddz_shared_status
-- ----------------------------
DROP TABLE IF EXISTS `million_ddz_shared_status`;
CREATE TABLE `million_ddz_shared_status`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `time` bigint(50) NULL DEFAULT 0 COMMENT '分享时间',
  `status` tinyint(4) UNSIGNED NULL DEFAULT 0,
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for naming_match_rank
-- ----------------------------
DROP TABLE IF EXISTS `naming_match_rank`;
CREATE TABLE `naming_match_rank`  (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `match_id` int(10) NOT NULL,
  `match_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `player_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `head_link` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `score` int(255) NULL DEFAULT 0,
  `hide_score` int(11) NULL DEFAULT 0,
  `rank` int(10) NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '比赛场次日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for nor_ddz_nor_race_log
-- ----------------------------
DROP TABLE IF EXISTS `nor_ddz_nor_race_log`;
CREATE TABLE `nor_ddz_nor_race_log`  (
  `id` int(10) UNSIGNED NOT NULL COMMENT '对局id，自增长主键',
  `game_id` int(10) NULL DEFAULT NULL,
  `begin_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` datetime(0) NULL DEFAULT NULL COMMENT '结束时间',
  `bomb_count` int(10) NULL DEFAULT 0 COMMENT '炸弹数量',
  `spring` int(10) NULL DEFAULT 0 COMMENT '春天（0 无，1春天，2 反春）',
  `base_score` int(10) NULL DEFAULT 0 COMMENT '底分',
  `base_rate` int(10) NULL DEFAULT 0 COMMENT '底倍',
  `max_rate` int(10) NULL DEFAULT 0 COMMENT '底倍',
  `fapai` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '发的牌',
  `operation_list` varbinary(500) NULL DEFAULT 0 COMMENT '操作序列',
  `dizhu_seat` int(10) NULL DEFAULT 0 COMMENT '地主座位号',
  `lz_card` int(10) NULL DEFAULT 0 COMMENT '癞子牌',
  `seat1_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat2_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat3_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `game_model` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for nor_ddz_nor_race_player_log
-- ----------------------------
DROP TABLE IF EXISTS `nor_ddz_nor_race_player_log`;
CREATE TABLE `nor_ddz_nor_race_player_log`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '对局id，自增长主键',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `race_id` int(11) NULL DEFAULT NULL,
  `seat` int(10) NULL DEFAULT 0 COMMENT '座位号',
  `score` int(10) NULL DEFAULT 0 COMMENT '得分',
  `rate` int(10) NULL DEFAULT 0 COMMENT '倍数',
  `bomb_count` int(10) NULL DEFAULT 0 COMMENT '炸弹数（自己的炸弹）',
  `spring` int(10) NULL DEFAULT 0 COMMENT '春天（0 无，1春天，2 反春，3 被春天，4被反春）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 13 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for nor_mj_xzdd_race_log
-- ----------------------------
DROP TABLE IF EXISTS `nor_mj_xzdd_race_log`;
CREATE TABLE `nor_mj_xzdd_race_log`  (
  `id` int(10) UNSIGNED NOT NULL COMMENT '对局id，自增长主键',
  `game_id` int(11) NULL DEFAULT NULL,
  `game_model` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '游戏模式，比如： nor_mj_zdd',
  `begin_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` datetime(0) NULL DEFAULT NULL COMMENT '结束时间',
  `init_rate` int(10) NULL DEFAULT NULL COMMENT '低倍',
  `init_stake` int(10) NULL DEFAULT 0 COMMENT '底分',
  `max_rate` int(10) NULL DEFAULT NULL,
  `fapai` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '发的牌',
  `operation_list` varbinary(1024) NULL DEFAULT 0 COMMENT '操作序列',
  `zhuang_seat` int(10) NULL DEFAULT 0 COMMENT '庄座位号',
  `seat1_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat2_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat3_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `seat4_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for nor_mj_xzdd_race_player_log
-- ----------------------------
DROP TABLE IF EXISTS `nor_mj_xzdd_race_player_log`;
CREATE TABLE `nor_mj_xzdd_race_player_log`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '对局id，自增长主键',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `race_id` int(11) NULL DEFAULT NULL,
  `seat` int(10) NULL DEFAULT 0 COMMENT '座位号',
  `score` int(10) NULL DEFAULT 0 COMMENT '得分',
  `multi` int(10) NULL DEFAULT 0 COMMENT '倍数',
  `gang_info` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0',
  `pai_info` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 21 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_asset
-- ----------------------------
DROP TABLE IF EXISTS `player_asset`;
CREATE TABLE `player_asset`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `diamond` bigint(20) NULL DEFAULT 0 COMMENT '钻石',
  `jing_bi` bigint(20) NULL DEFAULT 0,
  `shop_ticket` bigint(20) NULL DEFAULT 0 COMMENT '抵用券',
  `cash` bigint(20) NULL DEFAULT 0 COMMENT '现金',
  `shop_gold_sum` bigint(20) NULL DEFAULT 0 COMMENT '购物金，各面额的总数',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家财物表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_asset_log
-- ----------------------------
DROP TABLE IF EXISTS `player_asset_log`;
CREATE TABLE `player_asset_log`  (
  `log_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志 id ，主键',
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `date` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP,
  `asset_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '财物类型： match_ticket, room_card,shop_gold,cash',
  `change_value` bigint(20) NULL DEFAULT NULL COMMENT '变化量',
  `change_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '变化原因： weixin 微信充值； ali_pay 支付宝充值； 。。。',
  `current` bigint(20) NULL DEFAULT NULL COMMENT '变化后数量',
  `change_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '编号ID，外部数据，（如订单ID，对局ID）',
  `sync_seq` bigint(255) NULL DEFAULT NULL COMMENT '同步序号',
  `change_way` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `change_way_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`log_id`) USING BTREE,
  INDEX `index2`(`asset_type`) USING BTREE,
  INDEX `index3`(`change_type`) USING BTREE,
  INDEX `index4`(`change_id`) USING BTREE,
  INDEX `sync_seq`(`sync_seq`) USING BTREE,
  INDEX `id`(`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1107 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家财物日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_asset_refund
-- ----------------------------
DROP TABLE IF EXISTS `player_asset_refund`;
CREATE TABLE `player_asset_refund`  (
  `log_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志 id ，主键',
  `log_id_refund` int(10) UNSIGNED NOT NULL COMMENT '退款的日志id（目前只有报名费）',
  `seq_refund` bigint(50) NULL DEFAULT 0 COMMENT '退款的同步序号',
  PRIMARY KEY (`log_id`) USING BTREE,
  INDEX `log_id_refund`(`log_id_refund`) USING BTREE,
  INDEX `seq_refund`(`seq_refund`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = 'player_asset_log 表中 的退款记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_block_status
-- ----------------------------
DROP TABLE IF EXISTS `player_block_status`;
CREATE TABLE `player_block_status`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `block_status` tinyint(50) NULL DEFAULT 1,
  `block_time` bigint(50) NULL DEFAULT NULL COMMENT '昵称',
  `reason` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_block_status_log
-- ----------------------------
DROP TABLE IF EXISTS `player_block_status_log`;
CREATE TABLE `player_block_status_log`  (
  `id` int(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `block_status` tinyint(50) NULL DEFAULT 1,
  `block_time` bigint(50) NULL DEFAULT NULL COMMENT '昵称',
  `reason` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `log_time` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_broke_subsidy
-- ----------------------------
DROP TABLE IF EXISTS `player_broke_subsidy`;
CREATE TABLE `player_broke_subsidy`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `num` tinyint(20) NULL DEFAULT 0,
  `time` bigint(20) NULL DEFAULT 0,
  PRIMARY KEY (`player_id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家财物表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_change_type_refund
-- ----------------------------
DROP TABLE IF EXISTS `player_change_type_refund`;
CREATE TABLE `player_change_type_refund`  (
  `change_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '变化原因',
  `change_type_refund` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '退款的变化原因',
  PRIMARY KEY (`change_type`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '退款的消费类型定义表。记录 退款 和 消费 的类型对应关系' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_consume_statistics
-- ----------------------------
DROP TABLE IF EXISTS `player_consume_statistics`;
CREATE TABLE `player_consume_statistics`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `pay` bigint(50) NULL DEFAULT 0,
  `cost_jing_bi` bigint(50) NULL DEFAULT 0,
  `cost_shop_gold` bigint(50) NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '登录表\r\n近期登陆数据，离线超过一定时间则删除' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_device_info
-- ----------------------------
DROP TABLE IF EXISTS `player_device_info`;
CREATE TABLE `player_device_info`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `device_token` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '这家伙很懒，什么也没留下。' COMMENT '设备编号',
  `device_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '设备类型； ios / android',
  `refresh_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家最近使用的设备信息' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_dress_info
-- ----------------------------
DROP TABLE IF EXISTS `player_dress_info`;
CREATE TABLE `player_dress_info`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `dress_type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '0' COMMENT '有效期',
  `dress_id` int(255) NOT NULL DEFAULT 0,
  `num` int(255) NULL DEFAULT NULL,
  `time` bigint(255) NULL DEFAULT NULL,
  PRIMARY KEY (`player_id`, `dress_type`, `dress_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_dress_info_log
-- ----------------------------
DROP TABLE IF EXISTS `player_dress_info_log`;
CREATE TABLE `player_dress_info_log`  (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `dress_type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '有效期',
  `dress_id` int(255) NULL DEFAULT 0,
  `num` int(255) NULL DEFAULT NULL,
  `time` bigint(255) NULL DEFAULT NULL,
  `change_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `log_time` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_dressed
-- ----------------------------
DROP TABLE IF EXISTS `player_dressed`;
CREATE TABLE `player_dressed`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `dressed_head_frame` tinyint(20) NULL DEFAULT 0 COMMENT '有效期',
  PRIMARY KEY (`player_id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家财物表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_duiju_hongbao_award
-- ----------------------------
DROP TABLE IF EXISTS `player_duiju_hongbao_award`;
CREATE TABLE `player_duiju_hongbao_award`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `get_award_value` int(50) NULL DEFAULT NULL COMMENT '当日已经获得的对局红包',
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_everyday_shared_status
-- ----------------------------
DROP TABLE IF EXISTS `player_everyday_shared_status`;
CREATE TABLE `player_everyday_shared_status`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `type` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '0',
  `status` tinyint(4) UNSIGNED NULL DEFAULT 0,
  `time` bigint(50) NULL DEFAULT 0,
  PRIMARY KEY (`player_id`, `type`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_gift_bag_status
-- ----------------------------
DROP TABLE IF EXISTS `player_gift_bag_status`;
CREATE TABLE `player_gift_bag_status`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `gift_bag_id` tinyint(4) NOT NULL,
  `gift_bag_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `num` int(20) NULL DEFAULT 0,
  `time` bigint(20) NULL DEFAULT 0,
  PRIMARY KEY (`player_id`, `gift_bag_id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家财物表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_glory
-- ----------------------------
DROP TABLE IF EXISTS `player_glory`;
CREATE TABLE `player_glory`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `level` tinyint(20) NULL DEFAULT 0 COMMENT '有效期',
  `score` int(20) NULL DEFAULT 0 COMMENT '0 or 1',
  PRIMARY KEY (`player_id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家财物表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_goldpig_info
-- ----------------------------
DROP TABLE IF EXISTS `player_goldpig_info`;
CREATE TABLE `player_goldpig_info`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '玩家id',
  `is_buy_goldpig` tinyint(10) NULL DEFAULT NULL COMMENT '是否购买金猪礼包',
  `remain_task_num` mediumint(20) NULL DEFAULT NULL COMMENT '剩余的任务次数',
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_info
-- ----------------------------
DROP TABLE IF EXISTS `player_info`;
CREATE TABLE `player_info`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `sync_seq` int(11) NOT NULL DEFAULT 0 COMMENT '用户信息的同步序号,供后台业务系统同步数据',
  `kind` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT 'normal' COMMENT '种类： \'normal\',\'robot\',\'admin\'',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '未登陆用户' COMMENT '昵称',
  `head_image` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT 'http://jydown.jyhd919.cn/head_images/icon_128.png' COMMENT '头像,http链接',
  `sex` tinyint(11) NULL DEFAULT 1 COMMENT '性别： 0 女，1 男',
  `phone` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '手机号',
  `ali_pay` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '付宝号',
  `wechat` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '微信号',
  `sign` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '这家伙很懒，什么也没留下。' COMMENT '个人签名',
  `is_block` int(11) NULL DEFAULT 0 COMMENT '是否锁定； 0 未锁定； 1 锁定',
  `logined` tinyint(4) NULL DEFAULT 0 COMMENT '是否登录过：0 未登录；1 已登录',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `index2`(`sync_seq`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_ji_pai_qi
-- ----------------------------
DROP TABLE IF EXISTS `player_ji_pai_qi`;
CREATE TABLE `player_ji_pai_qi`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `valid_time` bigint(20) NULL DEFAULT 0 COMMENT '有效期',
  `always` tinyint(20) NULL DEFAULT 0 COMMENT '0 or 1',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家财物表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_ji_pai_qi_log
-- ----------------------------
DROP TABLE IF EXISTS `player_ji_pai_qi_log`;
CREATE TABLE `player_ji_pai_qi_log`  (
  `id` int(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `change_time` int(20) NULL DEFAULT 0,
  `valid_time` bigint(20) NULL DEFAULT 0 COMMENT '有效期',
  `always` tinyint(4) NULL DEFAULT NULL,
  `change_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '变化原因： weixin 微信充值； ali_pay 支付宝充值； 。。。',
  `change_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '编号ID，外部数据，（如订单ID，对局ID）',
  `change_way` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `change_way_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1394 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家财物表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_login
-- ----------------------------
DROP TABLE IF EXISTS `player_login`;
CREATE TABLE `player_login`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `login_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '玩家登陆的 ip 地址',
  `login_os` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '玩家登陆的操作系统',
  `login_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '玩家登陆时间',
  `logout_time` datetime(0) NULL DEFAULT NULL COMMENT '玩家登出时间',
  `on_line` int(11) NULL DEFAULT NULL COMMENT '当前是否在线： 1 在线； NULL  离线',
  `log_id` int(10) NOT NULL COMMENT '日志表中对应的 log_id',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '登录表\r\n近期登陆数据，离线超过一定时间则删除' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_login_log
-- ----------------------------
DROP TABLE IF EXISTS `player_login_log`;
CREATE TABLE `player_login_log`  (
  `log_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志 id ，主键',
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `login_ip` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '玩家登陆的 ip 地址',
  `login_os` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '玩家登陆的操作系统',
  `login_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '玩家登陆时间',
  `logout_time` datetime(0) NULL DEFAULT NULL COMMENT '玩家登出时间',
  PRIMARY KEY (`log_id`) USING BTREE,
  UNIQUE INDEX `log_id_UNIQUE`(`log_id`) USING BTREE,
  INDEX `login_time`(`login_time`) USING BTREE,
  INDEX `id`(`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1882 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '登录日志表\r\n' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_login_stat
-- ----------------------------
DROP TABLE IF EXISTS `player_login_stat`;
CREATE TABLE `player_login_stat`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `first_login_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '玩家登陆时间',
  `first_log_id` int(10) NOT NULL COMMENT '日志表中对应的 log_id',
  `last_login_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '玩家登陆时间',
  `last_log_id` int(10) NOT NULL COMMENT '日志表中对应的 log_id',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '登录统计表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_lottery
-- ----------------------------
DROP TABLE IF EXISTS `player_lottery`;
CREATE TABLE `player_lottery`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `lottery_time` int(20) NULL DEFAULT 0,
  `lottery_asset` int(20) NULL DEFAULT 0,
  `lottery_item_count` int(11) NULL DEFAULT NULL,
  `lottery_asset_time` bigint(50) NULL DEFAULT NULL,
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_merchant_order
-- ----------------------------
DROP TABLE IF EXISTS `player_merchant_order`;
CREATE TABLE `player_merchant_order`  (
  `order_id` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '订单号',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '玩家id',
  `amount` bigint(11) NOT NULL DEFAULT 0 COMMENT '消费总额',
  `props_json` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '消费多个面额消费张数的json: {\"10\":2,\"30\":1}',
  `shoping_desc` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '本次购买的描述信息，比如： 购买 xxx 商品 nnn 件。',
  `shoping_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '购物时间',
  PRIMARY KEY (`order_id`) USING BTREE,
  UNIQUE INDEX `order_id_UNIQUE`(`order_id`) USING BTREE,
  INDEX `index_shoping_time`(`shoping_time`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家在线下商家消费的订单表。' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_other_base_info
-- ----------------------------
DROP TABLE IF EXISTS `player_other_base_info`;
CREATE TABLE `player_other_base_info`  (
  `id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `real_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `phone` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `weixin` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `shengfen` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `chengshi` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `qu` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_other_base_info_change_log
-- ----------------------------
DROP TABLE IF EXISTS `player_other_base_info_change_log`;
CREATE TABLE `player_other_base_info_change_log`  (
  `log_id` int(11) NOT NULL AUTO_INCREMENT,
  `id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `real_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `phone` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `weixin` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `shengfen` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `chengshi` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `qu` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `op_player` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`log_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_pay_order
-- ----------------------------
DROP TABLE IF EXISTS `player_pay_order`;
CREATE TABLE `player_pay_order`  (
  `order_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '我们自己的订单ID',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '玩家id\n\n10111111111，ID由11位数字组成，前两位表示服务器号',
  `order_status` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'create' COMMENT '订单状态（\"init\" - 初始状态,\"create\" - 支付渠道已创建订单,\"error\" - 出错,\"fail\" - 失败,\"complete\" - 支付成功）',
  `error_desc` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `money_type` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'rmb' COMMENT '货币类型（如 rmb,dollar）',
  `money` int(11) NOT NULL DEFAULT 0 COMMENT '充值数量（单位：分）',
  `channel_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '支付渠道',
  `channel_account_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `source_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT 'game' COMMENT '来源类型： game 游戏内部； wxgzh 微信公众号',
  `product_id` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '我们自己的商品id',
  `product_count` int(11) NULL DEFAULT 1 COMMENT '商品数量',
  `product_desc` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '商品描述，用于显示在支付界面上',
  `is_test` int(11) NULL DEFAULT 0 COMMENT '是否是测试（1表示测试，0 表示真',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `channel_product_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '渠道方的产品id',
  `channel_order_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '渠道方的订单id',
  `itunes_trans_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT 'itunes 验证ID',
  `end_time` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '完成时间',
  PRIMARY KEY (`order_id`) USING BTREE,
  INDEX `index2`(`player_id`) USING BTREE,
  INDEX `create_time`(`create_time`) USING BTREE,
  INDEX `order_status`(`order_status`) USING BTREE,
  INDEX `channel_type`(`channel_type`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家充值订单表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_pay_order_detail
-- ----------------------------
DROP TABLE IF EXISTS `player_pay_order_detail`;
CREATE TABLE `player_pay_order_detail`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '我们自己的订单ID',
  `asset_type` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '资产类型',
  `asset_count` bigint(20) NOT NULL COMMENT '资产数量',
  `goods_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT 'buy' COMMENT '商品类型： \"buy\",\"gift\"',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '玩家充值订单详情表\r\n\r\n订单中的每个购买项' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_pay_order_detail_log
-- ----------------------------
DROP TABLE IF EXISTS `player_pay_order_detail_log`;
CREATE TABLE `player_pay_order_detail_log`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '我们自己的订单ID',
  `asset_type` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '资产类型',
  `asset_count` bigint(20) NOT NULL COMMENT '资产数量',
  `goods_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT 'buy' COMMENT '商品类型： \"buy\",\"gift\"',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '玩家充值订单详情表\r\n\r\n订单中的每个购买项' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_pay_order_log
-- ----------------------------
DROP TABLE IF EXISTS `player_pay_order_log`;
CREATE TABLE `player_pay_order_log`  (
  `order_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '我们自己的订单ID',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '玩家id\n\n10111111111，ID由11位数字组成，前两位表示服务器号',
  `order_status` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'create' COMMENT '订单状态（\"init\" - 初始状态,\"create\" - 支付渠道已创建订单,\"error\" - 出错,\"fail\" - 失败,\"complete\" - 支付成功）',
  `error_desc` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `money_type` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'rmb' COMMENT '货币类型（如 rmb,dollar）',
  `money` int(11) NOT NULL DEFAULT 0 COMMENT '充值数量（单位：分）',
  `channel_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '支付渠道',
  `channel_account_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `source_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT 'game' COMMENT '来源类型： game 游戏内部； wxgzh 微信公众号',
  `product_id` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '我们自己的商品id',
  `product_count` int(11) NULL DEFAULT 1 COMMENT '商品数量',
  `product_desc` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '商品描述，用于显示在支付界面上',
  `is_test` int(11) NULL DEFAULT 0 COMMENT '是否是测试（1表示测试，0 表示真',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `channel_product_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '渠道方的产品id',
  `channel_order_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '渠道方的订单id',
  `itunes_trans_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT 'itunes 验证ID',
  `end_time` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '完成时间',
  PRIMARY KEY (`order_id`) USING BTREE,
  INDEX `create_time`(`create_time`) USING BTREE,
  INDEX `order_status`(`order_status`) USING BTREE,
  INDEX `channel_type`(`channel_type`) USING BTREE,
  INDEX `index2`(`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家充值订单表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_pay_order_stat
-- ----------------------------
DROP TABLE IF EXISTS `player_pay_order_stat`;
CREATE TABLE `player_pay_order_stat`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '玩家id\n\n10111111111，ID由11位数字组成，前两位表示服务器号',
  `first_complete_time` datetime(0) NULL DEFAULT NULL COMMENT '第一个订单完成时间',
  `first_order_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '第一个订单ID',
  `last_complete_time` datetime(0) NULL DEFAULT NULL COMMENT '第二个订单完成时间',
  `last_order_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '第二个订单ID',
  `sum_money` int(11) NOT NULL DEFAULT 0 COMMENT '充值数量总计（单位：分）',
  PRIMARY KEY (`player_id`) USING BTREE,
  INDEX `index2`(`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家充值统计表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_prop
-- ----------------------------
DROP TABLE IF EXISTS `player_prop`;
CREATE TABLE `player_prop`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `prop_type` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'shop_ticket' COMMENT '道具类型。目前只有  shop_ticket（ 购物券）',
  `prop_count` bigint(50) NULL DEFAULT 0 COMMENT '数量',
  PRIMARY KEY (`id`, `prop_type`) USING BTREE,
  INDEX `ID_UNIQUE`(`id`) USING BTREE,
  INDEX `index3`(`prop_type`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家道具表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_prop_log
-- ----------------------------
DROP TABLE IF EXISTS `player_prop_log`;
CREATE TABLE `player_prop_log`  (
  `log_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志 id ，主键',
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `date` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP,
  `prop_type` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '道具类型。目前只有  shop_ticket（ 购物券）',
  `change_value` bigint(20) NULL DEFAULT NULL COMMENT '变化量',
  `change_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '变化原因： weixin 微信充值； ali_pay 支付宝充值； 。。。',
  `current` bigint(50) NULL DEFAULT NULL COMMENT '变化后数量',
  `change_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '编号ID，外部数据，（如订单ID，对局ID）',
  `shop_gold_sync_seq` bigint(50) NULL DEFAULT 0 COMMENT '购物金的同步序号,供后台业务系统同步数据',
  `change_way` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `change_way_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`log_id`) USING BTREE,
  INDEX `shop_gold_sync_seq`(`shop_gold_sync_seq`) USING BTREE,
  INDEX `index3`(`prop_type`) USING BTREE,
  INDEX `index4`(`change_type`) USING BTREE,
  INDEX `index5`(`change_id`) USING BTREE,
  INDEX `id`(`id`, `date`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家道具日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_prop_refund
-- ----------------------------
DROP TABLE IF EXISTS `player_prop_refund`;
CREATE TABLE `player_prop_refund`  (
  `log_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志 id ，主键',
  `log_id_refund` int(10) UNSIGNED NOT NULL COMMENT '退款的日志id（目前只有报名费）',
  `seq_refund` bigint(50) NULL DEFAULT 0 COMMENT '退款的同步序号',
  PRIMARY KEY (`log_id`) USING BTREE,
  INDEX `log_id_refund`(`log_id_refund`) USING BTREE,
  INDEX `seq_refund`(`seq_refund`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = 'player_prop_log 表中 的退款记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_register
-- ----------------------------
DROP TABLE IF EXISTS `player_register`;
CREATE TABLE `player_register`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `register_channel` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '注册渠道。 youke 游客；phone 手机号； weixin_gz 微信公众平台；weixin_kf 微信开放平台； 。。。',
  `login_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '注册渠道 提供的用户编号:电话号码，微信的unionid等',
  `introducer` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '介绍人',
  `register_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '注册时 用户设备的 ip 地址',
  `register_os` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '注册时 用户设备的 操作系统',
  `register_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `market_channel` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT 'normal' COMMENT '推广渠道',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `index2`(`register_channel`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '注册信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_shop_order
-- ----------------------------
DROP TABLE IF EXISTS `player_shop_order`;
CREATE TABLE `player_shop_order`  (
  `order_id` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '订单号',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '玩家id',
  `order_status` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'complete' COMMENT '订单状态（\"complete\" - 完成,\"refund\" - 退款）',
  `amount` bigint(11) NOT NULL DEFAULT 0 COMMENT '消费总额',
  `props_json` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '消费多个面额消费张数的json: {\"10\":2,\"30\":1}',
  `shoping_desc` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '本次购买的描述信息，比如： 购买 xxx 商品 nnn 件。',
  `shoping_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '购物时间',
  `refund_time` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '退款时间',
  PRIMARY KEY (`order_id`) USING BTREE,
  UNIQUE INDEX `order_id_UNIQUE`(`order_id`) USING BTREE,
  INDEX `index_shoping_time`(`shoping_time`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家商城订单表。玩家通过商城购买东西的订单。' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_shop_order_log
-- ----------------------------
DROP TABLE IF EXISTS `player_shop_order_log`;
CREATE TABLE `player_shop_order_log`  (
  `order_id` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '订单号',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '玩家id',
  `order_status` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'complete' COMMENT '订单状态（\"complete\" - 完成,\"refund\" - 退款）',
  `amount` bigint(11) NOT NULL DEFAULT 0 COMMENT '消费总额',
  `props_json` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '消费多个道具的json: {\"shop_gold_10\":2,\"shop_gold_100\":1}',
  `shoping_desc` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '本次购买的描述信息，比如： 购买 xxx 商品 nnn 件。',
  `shoping_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '购物时间',
  `refund_time` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '退款时间',
  PRIMARY KEY (`order_id`) USING BTREE,
  UNIQUE INDEX `order_id_UNIQUE`(`order_id`) USING BTREE,
  INDEX `index_shoping_time`(`shoping_time`) USING BTREE,
  INDEX `index4`(`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家商城订单表。玩家通过商城购买东西的订单。' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_stepstep_money
-- ----------------------------
DROP TABLE IF EXISTS `player_stepstep_money`;
CREATE TABLE `player_stepstep_money`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `now_big_step` tinyint(10) NULL DEFAULT NULL COMMENT '所在的大步骤',
  `now_little_step` tinyint(10) NULL DEFAULT NULL COMMENT '所在的小步骤',
  `last_op_time` bigint(50) NULL DEFAULT NULL COMMENT '最后操作的时间',
  `can_do_big_step` tinyint(10) NULL DEFAULT NULL COMMENT '可以做的大步骤',
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_task
-- ----------------------------
DROP TABLE IF EXISTS `player_task`;
CREATE TABLE `player_task`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `task_id` int(20) NOT NULL DEFAULT 0,
  `process` int(20) NULL DEFAULT 0,
  `task_round` int(20) NULL DEFAULT 1 COMMENT '当前进行的任务次数，该领取的任务等级',
  `create_time` bigint(50) NULL DEFAULT NULL,
  PRIMARY KEY (`player_id`, `task_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_task_log
-- ----------------------------
DROP TABLE IF EXISTS `player_task_log`;
CREATE TABLE `player_task_log`  (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '玩家id',
  `task_id` int(20) NULL DEFAULT NULL COMMENT '任务id',
  `progress_change` mediumint(20) NULL DEFAULT NULL COMMENT '任务进度改变值',
  `now_progress` mediumint(20) NULL DEFAULT NULL COMMENT '当前进度值',
  `time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '当前的记录时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 10 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_verify
-- ----------------------------
DROP TABLE IF EXISTS `player_verify`;
CREATE TABLE `player_verify`  (
  `login_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '登录id，电话号码，微信的unionid等',
  `channel_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '登录渠道类型。 youke 游客；phone 手机号； weixin_gz 微信公众平台；weixin_kf 微信开放平台；。。。',
  `password` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '密码',
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `refresh_token` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `extend_1` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '其他 id。 某些登录渠道可能有 额外的id，例如微信的 unionid',
  `extend_2` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`login_id`, `channel_type`) USING BTREE,
  INDEX `index2`(`id`) USING BTREE,
  INDEX `index3`(`extend_1`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '登录验证表\n' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_vip
-- ----------------------------
DROP TABLE IF EXISTS `player_vip`;
CREATE TABLE `player_vip`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `vip_time` bigint(50) NULL DEFAULT NULL COMMENT 'vip到期的时间(时间戳)',
  `vip_day_time` int(10) NULL DEFAULT NULL COMMENT '剩余的vip的天数',
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_vip_buy_record
-- ----------------------------
DROP TABLE IF EXISTS `player_vip_buy_record`;
CREATE TABLE `player_vip_buy_record`  (
  `id` int(20) NOT NULL,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '购买 vip 的玩家',
  `payback_player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '获得 FL 的玩家',
  `payback_value` int(20) NULL DEFAULT NULL COMMENT 'FL金额',
  `buy_vip_day` int(10) NULL DEFAULT NULL COMMENT '购买的vip的天数',
  `buy_time` bigint(50) NULL DEFAULT NULL COMMENT '购买vip日期',
  `buy_time_year` mediumint(20) NULL DEFAULT NULL COMMENT '购买vip日期_年',
  `buy_time_month` tinyint(20) NULL DEFAULT NULL COMMENT '购买vip日期_月',
  `buy_time_day` tinyint(20) NULL DEFAULT NULL COMMENT '购买vip日期_日',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_vip_generalize
-- ----------------------------
DROP TABLE IF EXISTS `player_vip_generalize`;
CREATE TABLE `player_vip_generalize`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `award_value` int(50) NULL DEFAULT NULL COMMENT '推广奖励值，可领取的',
  `today_get_award` int(50) NULL DEFAULT NULL COMMENT '今日已经领取的奖励值',
  `last_get_time` bigint(50) NULL DEFAULT NULL COMMENT '上次领取的时间',
  `total_award_value` int(50) NULL DEFAULT NULL COMMENT '总共获得的推广奖励(领取了和未领取的)',
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_vip_generalize_extract_record
-- ----------------------------
DROP TABLE IF EXISTS `player_vip_generalize_extract_record`;
CREATE TABLE `player_vip_generalize_extract_record`  (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `extract_value` int(20) NULL DEFAULT NULL COMMENT '提取值',
  `extract_time` bigint(50) NULL DEFAULT NULL COMMENT '日期',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_vip_reward_task
-- ----------------------------
DROP TABLE IF EXISTS `player_vip_reward_task`;
CREATE TABLE `player_vip_reward_task`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `reward_task_status` tinyint(20) NULL DEFAULT NULL COMMENT '0是未完成，1是完成了未领取，2是领取了',
  `last_op_time` bigint(50) NULL DEFAULT NULL COMMENT '上次操作的时间',
  `award_value` int(11) NULL DEFAULT NULL COMMENT '奖励值的多少(当日返奖任务的奖励值)',
  `total_get_award` int(50) NULL DEFAULT NULL COMMENT '总共已经获取到的奖励值，不能领的',
  `total_find_award` int(50) NULL DEFAULT NULL COMMENT '总共找回的奖励值,还可以领取的',
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '玩家vip返奖任务，(对局红包任务)' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_vip_reward_task_record
-- ----------------------------
DROP TABLE IF EXISTS `player_vip_reward_task_record`;
CREATE TABLE `player_vip_reward_task_record`  (
  `id` int(50) NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `get_award_value` int(50) NULL DEFAULT NULL COMMENT '当日领取或找回的奖励值;或领取的找回的奖励值',
  `status` tinyint(10) NULL DEFAULT NULL COMMENT '当日的任务状态, 0 表示未完成；1完成了系统帮领；2完成并领取了；3领取了帮领(找回)的奖励',
  `time` bigint(50) NULL DEFAULT NULL COMMENT '任务结算的时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = 'vip返奖任务的每日记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_withdraw
-- ----------------------------
DROP TABLE IF EXISTS `player_withdraw`;
CREATE TABLE `player_withdraw`  (
  `withdraw_id` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `withdraw_status` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '状态（init,error,fail,complete）',
  `error_desc` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `money` int(11) NOT NULL DEFAULT 0 COMMENT '提现金额（单位：分）',
  `channel_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '收款渠道',
  `channel_withdraw_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '渠道方的交易id',
  `channel_receiver_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '渠道收款方id',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '创建时间',
  `complete_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '完成时间',
  `comment` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`withdraw_id`) USING BTREE,
  INDEX `index2`(`complete_time`, `withdraw_status`) USING BTREE,
  INDEX `plwd_playerid_index`(`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '玩家提现表（玩家提取现金）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_withdraw_log
-- ----------------------------
DROP TABLE IF EXISTS `player_withdraw_log`;
CREATE TABLE `player_withdraw_log`  (
  `withdraw_id` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `withdraw_status` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '状态（init,error,fail,complete）',
  `error_desc` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `money` int(11) NOT NULL DEFAULT 0 COMMENT '提现金额（单位：分）',
  `channel_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '收款渠道',
  `channel_withdraw_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '渠道方的交易id',
  `channel_receiver_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '渠道收款方id',
  `create_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '创建时间',
  `complete_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '完成时间',
  `comment` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`withdraw_id`) USING BTREE,
  INDEX `plwdlog_playerid_index`(`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '玩家提现表（玩家提取现金）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_xsyd_status
-- ----------------------------
DROP TABLE IF EXISTS `player_xsyd_status`;
CREATE TABLE `player_xsyd_status`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `status` tinyint(4) NULL DEFAULT NULL,
  `time` datetime(0) NULL DEFAULT NULL,
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_zajindan_info
-- ----------------------------
DROP TABLE IF EXISTS `player_zajindan_info`;
CREATE TABLE `player_zajindan_info`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `wood_hammer_num` int(50) NULL DEFAULT NULL COMMENT '木锤子数量',
  `iron_hammer_num` int(50) NULL DEFAULT NULL COMMENT '铁锤子数量',
  `silver_hammer_num` int(50) NULL DEFAULT NULL COMMENT '银锤子数量',
  `gold_hammer_num` int(50) NULL DEFAULT NULL COMMENT '金锤子数量',
  `today_get_award` int(50) NULL DEFAULT NULL COMMENT '今日获得的奖励',
  `today_id` int(50) NULL DEFAULT NULL COMMENT '今天的id，具体是距离某一天的多少天',
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_zajindan_log
-- ----------------------------
DROP TABLE IF EXISTS `player_zajindan_log`;
CREATE TABLE `player_zajindan_log`  (
  `id` int(255) NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '玩家id',
  `round_id` int(50) NULL DEFAULT NULL COMMENT '轮数',
  `egg_no` tinyint(20) NULL DEFAULT NULL COMMENT '砸的蛋的id',
  `award_id` tinyint(20) NULL DEFAULT NULL COMMENT '奖励id',
  `award_type` tinyint(10) NULL DEFAULT NULL COMMENT '奖励类型',
  `award_value` int(50) NULL DEFAULT NULL COMMENT '奖励值',
  `award_data` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '奖励的str,逗号分割,,奖励的翻倍数',
  `time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 228 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for player_zajindan_round_log
-- ----------------------------
DROP TABLE IF EXISTS `player_zajindan_round_log`;
CREATE TABLE `player_zajindan_round_log`  (
  `id` int(50) NOT NULL,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '玩家id',
  `hammer_id` tinyint(10) NULL DEFAULT NULL COMMENT '锤子id',
  `award_data` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '奖励string,逗号分割,,奖励的翻倍数',
  `time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for prop_type
-- ----------------------------
DROP TABLE IF EXISTS `prop_type`;
CREATE TABLE `prop_type`  (
  `prop_type` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '道具类型',
  `prop_group` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '道具分组，对于类似面额的道具，同属于一种',
  `value` int(11) NULL DEFAULT 1 COMMENT '道具的值，对于 面额，为实际值。默认为 1',
  PRIMARY KEY (`prop_type`) USING BTREE,
  INDEX `prop_group`(`prop_group`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '道具类型信息' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for real_name_authentication
-- ----------------------------
DROP TABLE IF EXISTS `real_name_authentication`;
CREATE TABLE `real_name_authentication`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `identity_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for redeem_code_log
-- ----------------------------
DROP TABLE IF EXISTS `redeem_code_log`;
CREATE TABLE `redeem_code_log`  (
  `key_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `type` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `comment` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `use_time` datetime(6) NULL DEFAULT NULL,
  PRIMARY KEY (`key_code`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for sczd_activity_info
-- ----------------------------
DROP TABLE IF EXISTS `sczd_activity_info`;
CREATE TABLE `sczd_activity_info`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '玩家id',
  `tglb_contribution_for_parent` int(50) NULL DEFAULT NULL COMMENT '推广礼包给父亲贡献的值',
  `bbsc_contribution_for_parent` int(50) NULL DEFAULT NULL COMMENT '步步生财给父亲贡献的值',
  `tglb_contribution_cache` int(50) NULL DEFAULT NULL COMMENT '我获得的推广礼包的贡献的缓存(儿子给我的)',
  `bbsc_contribution_cache` int(50) NULL DEFAULT NULL COMMENT '我获得的步步生财的贡献的缓存(儿子给我的)',
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for sczd_gjhhr_info
-- ----------------------------
DROP TABLE IF EXISTS `sczd_gjhhr_info`;
CREATE TABLE `sczd_gjhhr_info`  (
  `id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `become_time` datetime(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for sczd_gjhhr_info_change_log
-- ----------------------------
DROP TABLE IF EXISTS `sczd_gjhhr_info_change_log`;
CREATE TABLE `sczd_gjhhr_info_change_log`  (
  `log_id` int(11) NOT NULL AUTO_INCREMENT,
  `id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `become_time` datetime(0) NULL DEFAULT NULL,
  `op_player` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `change_time` datetime(0) NULL DEFAULT NULL,
  PRIMARY KEY (`log_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for sczd_gjhhr_settle_log
-- ----------------------------
DROP TABLE IF EXISTS `sczd_gjhhr_settle_log`;
CREATE TABLE `sczd_gjhhr_settle_log`  (
  `no` int(11) NOT NULL AUTO_INCREMENT,
  `id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `achievements` bigint(20) NULL DEFAULT NULL,
  `tuikuan` bigint(20) NULL DEFAULT NULL,
  `income` bigint(20) NULL DEFAULT NULL,
  `time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`no`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for sczd_gjhhr_ticheng_cfg
-- ----------------------------
DROP TABLE IF EXISTS `sczd_gjhhr_ticheng_cfg`;
CREATE TABLE `sczd_gjhhr_ticheng_cfg`  (
  `id` int(11) NOT NULL,
  `achievements` bigint(20) NULL DEFAULT NULL,
  `proportion` float NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for sczd_income_deatails_log
-- ----------------------------
DROP TABLE IF EXISTS `sczd_income_deatails_log`;
CREATE TABLE `sczd_income_deatails_log`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '玩家id',
  `parent_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '父亲节点',
  `treasure_type` tinyint(10) NULL DEFAULT NULL COMMENT '产生财富的原因类型(是步步生财的第n天还是推广礼包)',
  `treasure_value` int(50) NULL DEFAULT NULL COMMENT '财富值',
  `time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '产生时间',
  `is_active` tinyint(10) NULL DEFAULT NULL COMMENT '是否激活，1=true,0=false',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for sczd_player_all_achievements
-- ----------------------------
DROP TABLE IF EXISTS `sczd_player_all_achievements`;
CREATE TABLE `sczd_player_all_achievements`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `all_achievements` bigint(50) NULL DEFAULT NULL,
  `yesterday_all_achievements` bigint(50) NULL DEFAULT NULL COMMENT '获得的时间',
  `tuikuan` int(11) NULL DEFAULT NULL,
  `yesterday_tuikuan` int(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 105560 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for sczd_player_base_info
-- ----------------------------
DROP TABLE IF EXISTS `sczd_player_base_info`;
CREATE TABLE `sczd_player_base_info`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '玩家id',
  `total_get_award` int(20) NULL DEFAULT NULL COMMENT '总共获得的奖励值',
  `is_activate_profit` tinyint(10) NULL DEFAULT NULL COMMENT '是否激活收益，1 = true,0 = false',
  `total_contribution_for_parent` int(50) NULL DEFAULT NULL COMMENT '我对邀请人的总贡献值',
  `all_son_count` int(11) NULL DEFAULT NULL,
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for sczd_player_day_achievements_log
-- ----------------------------
DROP TABLE IF EXISTS `sczd_player_day_achievements_log`;
CREATE TABLE `sczd_player_day_achievements_log`  (
  `no` int(11) NOT NULL AUTO_INCREMENT,
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `achievements` bigint(20) NULL DEFAULT NULL,
  `tuikuan` bigint(20) NULL DEFAULT NULL,
  `all_achievements` bigint(20) NULL DEFAULT NULL,
  `all_tuikuan` bigint(20) NULL DEFAULT NULL,
  `time` datetime(0) NULL DEFAULT NULL,
  PRIMARY KEY (`no`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for sczd_relation_data
-- ----------------------------
DROP TABLE IF EXISTS `sczd_relation_data`;
CREATE TABLE `sczd_relation_data`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户id',
  `parent_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '上级玩家id',
  `is_tgy` tinyint(11) NULL DEFAULT 0 COMMENT '是否推广员。 1 是； 0 否。',
  `is_gjhhr` tinyint(11) NULL DEFAULT 0 COMMENT '是否代理。 1 是； 0 否。',
  `son_count` int(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `parent_id`(`parent_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '俱乐部 ，或者叫：分销系统/牌友圈/推广系统' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for shipping_address
-- ----------------------------
DROP TABLE IF EXISTS `shipping_address`;
CREATE TABLE `shipping_address`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `phone_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for statistics_player_ddz_win
-- ----------------------------
DROP TABLE IF EXISTS `statistics_player_ddz_win`;
CREATE TABLE `statistics_player_ddz_win`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `dizhu_win_count` int(20) NULL DEFAULT 0 COMMENT '地主胜利',
  `nongmin_win_count` int(20) NULL DEFAULT 0 COMMENT '胜利',
  `defeated_count` int(20) NULL DEFAULT 0 COMMENT '失败',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for statistics_player_freestyle_mjxl
-- ----------------------------
DROP TABLE IF EXISTS `statistics_player_freestyle_mjxl`;
CREATE TABLE `statistics_player_freestyle_mjxl`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `win_count` int(20) NULL DEFAULT 0 COMMENT '胜利',
  `defeated_count` int(20) NULL DEFAULT 0 COMMENT '失败',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for statistics_player_freestyle_tyddz
-- ----------------------------
DROP TABLE IF EXISTS `statistics_player_freestyle_tyddz`;
CREATE TABLE `statistics_player_freestyle_tyddz`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `dizhu_win_count` int(20) NULL DEFAULT 0 COMMENT '地主胜利',
  `nongmin_win_count` int(20) NULL DEFAULT 0 COMMENT '胜利',
  `defeated_count` int(20) NULL DEFAULT 0 COMMENT '失败',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for statistics_player_match_ddz
-- ----------------------------
DROP TABLE IF EXISTS `statistics_player_match_ddz`;
CREATE TABLE `statistics_player_match_ddz`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `dizhu_win_count` int(20) NULL DEFAULT 0 COMMENT '比赛券',
  `nongmin_win_count` int(20) NULL DEFAULT 0 COMMENT '房卡',
  `defeated_count` int(20) NULL DEFAULT 0 COMMENT '房卡',
  `first` int(20) NULL DEFAULT 0 COMMENT '购物金',
  `second` int(20) NULL DEFAULT 0 COMMENT '现金',
  `third` int(20) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for statistics_player_match_rank
-- ----------------------------
DROP TABLE IF EXISTS `statistics_player_match_rank`;
CREATE TABLE `statistics_player_match_rank`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `first` int(20) NULL DEFAULT 0 COMMENT '购物金',
  `second` int(20) NULL DEFAULT 0 COMMENT '现金',
  `third` int(20) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for statistics_player_million_ddz
-- ----------------------------
DROP TABLE IF EXISTS `statistics_player_million_ddz`;
CREATE TABLE `statistics_player_million_ddz`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `dizhu_win_count` int(20) NULL DEFAULT 0 COMMENT '比赛券',
  `nongmin_win_count` int(20) NULL DEFAULT 0 COMMENT '房卡',
  `defeated_count` int(20) NULL DEFAULT 0 COMMENT '房卡',
  `final_win` int(20) NULL DEFAULT 0 COMMENT '购物金',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for statistics_player_mj_win
-- ----------------------------
DROP TABLE IF EXISTS `statistics_player_mj_win`;
CREATE TABLE `statistics_player_mj_win`  (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '10111111111，ID由11位数字组成，前两位表示服务器号',
  `win_count` int(20) NULL DEFAULT 0 COMMENT '胜利',
  `defeated_count` int(20) NULL DEFAULT 0 COMMENT '失败',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `ID_UNIQUE`(`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for statistics_system_realtime
-- ----------------------------
DROP TABLE IF EXISTS `statistics_system_realtime`;
CREATE TABLE `statistics_system_realtime`  (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增长编号',
  `time` datetime(0) NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
  `channel` varchar(45) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT 'youke' COMMENT '用户所属渠道',
  `player_count` int(255) UNSIGNED NOT NULL DEFAULT 0 COMMENT '在线人数',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `time`(`time`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1028 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '实时统计数据' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for system_error
-- ----------------------------
DROP TABLE IF EXISTS `system_error`;
CREATE TABLE `system_error`  (
  `error_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '错误类型',
  `error_sn` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '错误标识号，和错误类型和数据相关',
  `error_info` varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '错误内容',
  PRIMARY KEY (`error_name`, `error_sn`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '数据库错误记录。通常由存储过程产生' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for system_variant
-- ----------------------------
DROP TABLE IF EXISTS `system_variant`;
CREATE TABLE `system_variant`  (
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `value` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `descript` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`name`) USING BTREE,
  UNIQUE INDEX `name_UNIQUE`(`name`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '系统变量，一些需要持久存放的 key - value 值' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for vip_sc_buy_record
-- ----------------------------
DROP TABLE IF EXISTS `vip_sc_buy_record`;
CREATE TABLE `vip_sc_buy_record`  (
  `buy_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '订单 id ，用于标识一次购买',
  `status` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT 'init' COMMENT '状态。init 初始状态；cur 执行中； end 结束。',
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '玩家id',
  `buy_time` datetime(0) NULL DEFAULT NULL COMMENT '购买时间',
  `buy_vip_day` int(10) NULL DEFAULT NULL COMMENT '购买的vip的天数',
  `price` int(10) NULL DEFAULT NULL COMMENT '费用（人民币，分）',
  `fanjiang` int(10) NULL DEFAULT NULL COMMENT '费用（人民币，分）',
  `present` bigint(10) NULL DEFAULT NULL COMMENT '赠送鲸币数量',
  PRIMARY KEY (`buy_id`) USING BTREE,
  INDEX `player_id`(`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '每次 vip 购买的执行状态' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for vip_sc_data
-- ----------------------------
DROP TABLE IF EXISTS `vip_sc_data`;
CREATE TABLE `vip_sc_data`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '玩家id',
  `remain_vip_count` bigint(255) NOT NULL COMMENT '剩余vip次数  一次10天（暂定）',
  `vipfanjiang_debt` bigint(255) NOT NULL COMMENT 'vip返奖 剩下的vip总和  分期还账，不包括当期',
  `presented_debt` bigint(255) NULL DEFAULT NULL COMMENT '充值送金币的剩余 债务  分期还账，不包括当期',
  `status` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT 'init' COMMENT '状态：\"init\" 初始状态, \"run\" 执行中， \"done\" 完成',
  `cur_day_index` int(255) NULL DEFAULT 1 COMMENT '当前是第几天',
  `cur_vip_start_time` datetime(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '当前vip开始时间（10天）',
  `cur_debt` bigint(255) NULL DEFAULT 0 COMMENT '本期债务',
  `cur_remain_debt` bigint(255) NULL DEFAULT 0 COMMENT '本期已还的债务',
  `cur_qhtg_cost` bigint(255) NULL DEFAULT 0 COMMENT '当前强化托管的输赢情况',
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '正在进行中的 vip ，一次购买为单位，包含 n 个周期，一个周期暂定 10 天' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for vip_sc_days
-- ----------------------------
DROP TABLE IF EXISTS `vip_sc_days`;
CREATE TABLE `vip_sc_days`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '玩家id',
  `day_index` int(255) NOT NULL COMMENT '天的序号',
  `today_debt` bigint(255) NULL DEFAULT 0 COMMENT '今天的总债务',
  `done_debt` bigint(255) NULL DEFAULT 0 COMMENT '债务完成量',
  `game_count` bigint(255) NULL DEFAULT 0 COMMENT '今天已经进行的游戏次数',
  `qhtg_vd` bigint(255) NULL DEFAULT 0 COMMENT '当前强化托管的输赢情况',
  `today_lucky` bigint(255) NULL DEFAULT 0 COMMENT '今天总红包量',
  `done_luck` bigint(255) NULL DEFAULT 0 COMMENT '已完成红包',
  PRIMARY KEY (`player_id`, `day_index`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for zy_city_match_fs_lose
-- ----------------------------
DROP TABLE IF EXISTS `zy_city_match_fs_lose`;
CREATE TABLE `zy_city_match_fs_lose`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `rank` int(10) NULL DEFAULT NULL,
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '比赛场次日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for zy_city_match_hx_lose
-- ----------------------------
DROP TABLE IF EXISTS `zy_city_match_hx_lose`;
CREATE TABLE `zy_city_match_hx_lose`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '比赛场次日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for zy_city_match_rank_fs
-- ----------------------------
DROP TABLE IF EXISTS `zy_city_match_rank_fs`;
CREATE TABLE `zy_city_match_rank_fs`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `award` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `rank` int(10) NULL DEFAULT NULL,
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '比赛场次日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for zy_city_match_rank_hx
-- ----------------------------
DROP TABLE IF EXISTS `zy_city_match_rank_hx`;
CREATE TABLE `zy_city_match_rank_hx`  (
  `player_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `award` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '',
  `rank` int(10) NULL DEFAULT NULL,
  PRIMARY KEY (`player_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '比赛场次日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- View structure for player_first_login
-- ----------------------------
DROP VIEW IF EXISTS `player_first_login`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `player_first_login` AS select `a`.`id` AS `id`,`a`.`first_login_time` AS `login_time` from (`jygame`.`player_login_stat` `a` join (select `jygame`.`player_verify`.`login_id` AS `login_id`,`jygame`.`player_verify`.`channel_type` AS `channel_type`,`jygame`.`player_verify`.`password` AS `password`,`jygame`.`player_verify`.`id` AS `id`,`jygame`.`player_verify`.`refresh_token` AS `refresh_token`,`jygame`.`player_verify`.`extend_1` AS `extend_1`,`jygame`.`player_verify`.`extend_2` AS `extend_2` from `jygame`.`player_verify` where (`jygame`.`player_verify`.`channel_type` = 'wechat')) `b` on((`a`.`id` = `b`.`id`)));

-- ----------------------------
-- View structure for player_first_pay
-- ----------------------------
DROP VIEW IF EXISTS `player_first_pay`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `player_first_pay` AS select `a`.`order_id` AS `order_id`,`a`.`player_id` AS `player_id`,`a`.`order_status` AS `order_status`,`a`.`error_desc` AS `error_desc`,`a`.`money_type` AS `money_type`,`a`.`money` AS `money`,`a`.`channel_type` AS `channel_type`,`a`.`channel_account_id` AS `channel_account_id`,`a`.`source_type` AS `source_type`,`a`.`product_id` AS `product_id`,`a`.`product_count` AS `product_count`,`a`.`product_desc` AS `product_desc`,`a`.`is_test` AS `is_test`,`a`.`create_time` AS `create_time`,`a`.`channel_product_id` AS `channel_product_id`,`a`.`channel_order_id` AS `channel_order_id`,`a`.`itunes_trans_id` AS `itunes_trans_id`,`a`.`end_time` AS `end_time` from (`jygame`.`player_pay_order_all` `a` join (select `player_pay_order_all`.`player_id` AS `player_id`,min(`player_pay_order_all`.`create_time`) AS `create_time` from `jygame`.`player_pay_order_all` group by `player_pay_order_all`.`player_id`) `b` on(((`a`.`player_id` = `b`.`player_id`) and (`a`.`create_time` = `b`.`create_time`))));

-- ----------------------------
-- View structure for player_friendgame_record
-- ----------------------------
DROP VIEW IF EXISTS `player_friendgame_record`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `player_friendgame_record` AS select `a`.`id` AS `id`,`a`.`game_name` AS `game_name`,`a`.`time` AS `time`,`a`.`room_no` AS `room_no`,`a`.`player_id` AS `player_id` from (select `jygame`.`friendgame_history_record`.`id` AS `id`,`jygame`.`friendgame_history_record`.`game_name` AS `game_name`,`jygame`.`friendgame_history_record`.`time` AS `time`,`jygame`.`friendgame_history_record`.`room_no` AS `room_no`,`jygame`.`friendgame_history_record`.`p1_id` AS `player_id` from `jygame`.`friendgame_history_record` where (`jygame`.`friendgame_history_record`.`p1_id` is not null)) `a` union select `b`.`id` AS `id`,`b`.`game_name` AS `game_name`,`b`.`time` AS `time`,`b`.`room_no` AS `room_no`,`b`.`player_id` AS `player_id` from (select `jygame`.`friendgame_history_record`.`id` AS `id`,`jygame`.`friendgame_history_record`.`game_name` AS `game_name`,`jygame`.`friendgame_history_record`.`time` AS `time`,`jygame`.`friendgame_history_record`.`room_no` AS `room_no`,`jygame`.`friendgame_history_record`.`p2_id` AS `player_id` from `jygame`.`friendgame_history_record` where (`jygame`.`friendgame_history_record`.`p2_id` is not null)) `b` union select `c`.`id` AS `id`,`c`.`game_name` AS `game_name`,`c`.`time` AS `time`,`c`.`room_no` AS `room_no`,`c`.`player_id` AS `player_id` from (select `jygame`.`friendgame_history_record`.`id` AS `id`,`jygame`.`friendgame_history_record`.`game_name` AS `game_name`,`jygame`.`friendgame_history_record`.`time` AS `time`,`jygame`.`friendgame_history_record`.`room_no` AS `room_no`,`jygame`.`friendgame_history_record`.`p3_id` AS `player_id` from `jygame`.`friendgame_history_record` where (`jygame`.`friendgame_history_record`.`p3_id` is not null)) `c` union select `d`.`id` AS `id`,`d`.`game_name` AS `game_name`,`d`.`time` AS `time`,`d`.`room_no` AS `room_no`,`d`.`player_id` AS `player_id` from (select `jygame`.`friendgame_history_record`.`id` AS `id`,`jygame`.`friendgame_history_record`.`game_name` AS `game_name`,`jygame`.`friendgame_history_record`.`time` AS `time`,`jygame`.`friendgame_history_record`.`room_no` AS `room_no`,`jygame`.`friendgame_history_record`.`p4_id` AS `player_id` from `jygame`.`friendgame_history_record` where (`jygame`.`friendgame_history_record`.`p4_id` is not null)) `d`;

-- ----------------------------
-- View structure for player_pay_order_all
-- ----------------------------
DROP VIEW IF EXISTS `player_pay_order_all`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `player_pay_order_all` AS select `player_pay_order_log`.`order_id` AS `order_id`,`player_pay_order_log`.`player_id` AS `player_id`,`player_pay_order_log`.`order_status` AS `order_status`,`player_pay_order_log`.`error_desc` AS `error_desc`,`player_pay_order_log`.`money_type` AS `money_type`,`player_pay_order_log`.`money` AS `money`,`player_pay_order_log`.`channel_type` AS `channel_type`,`player_pay_order_log`.`channel_account_id` AS `channel_account_id`,`player_pay_order_log`.`source_type` AS `source_type`,`player_pay_order_log`.`product_id` AS `product_id`,`player_pay_order_log`.`product_count` AS `product_count`,`player_pay_order_log`.`product_desc` AS `product_desc`,`player_pay_order_log`.`is_test` AS `is_test`,`player_pay_order_log`.`create_time` AS `create_time`,`player_pay_order_log`.`channel_product_id` AS `channel_product_id`,`player_pay_order_log`.`channel_order_id` AS `channel_order_id`,`player_pay_order_log`.`itunes_trans_id` AS `itunes_trans_id`,`player_pay_order_log`.`end_time` AS `end_time` from `player_pay_order_log` union select `player_pay_order`.`order_id` AS `order_id`,`player_pay_order`.`player_id` AS `player_id`,`player_pay_order`.`order_status` AS `order_status`,`player_pay_order`.`error_desc` AS `error_desc`,`player_pay_order`.`money_type` AS `money_type`,`player_pay_order`.`money` AS `money`,`player_pay_order`.`channel_type` AS `channel_type`,`player_pay_order`.`channel_account_id` AS `channel_account_id`,`player_pay_order`.`source_type` AS `source_type`,`player_pay_order`.`product_id` AS `product_id`,`player_pay_order`.`product_count` AS `product_count`,`player_pay_order`.`product_desc` AS `product_desc`,`player_pay_order`.`is_test` AS `is_test`,`player_pay_order`.`create_time` AS `create_time`,`player_pay_order`.`channel_product_id` AS `channel_product_id`,`player_pay_order`.`channel_order_id` AS `channel_order_id`,`player_pay_order`.`itunes_trans_id` AS `itunes_trans_id`,`player_pay_order`.`end_time` AS `end_time` from `player_pay_order`;

-- ----------------------------
-- Procedure structure for add_sczd_palyer_contribute
-- ----------------------------
DROP PROCEDURE IF EXISTS `add_sczd_palyer_contribute`;
delimiter ;;
CREATE PROCEDURE `add_sczd_palyer_contribute`(IN `_player_id` varchar(100),
IN `_parent_id` varchar(100),
IN `parent_active` int,
IN `change_type` varchar(50),
IN `contribut_type` varchar(50),
IN `contribute_value` int)
BEGIN
	
	update sczd_player_base_info set total_contribution_for_parent = total_contribution_for_parent + contribute_value 
	where player_id = _player_id;
	
	if change_type = 'bbsc' then
		update sczd_activity_info set bbsc_contribution_for_parent = bbsc_contribution_for_parent + contribute_value 
		where player_id = _player_id;
		
		if parent_active=0 then
			update sczd_activity_info set bbsc_contribution_cache = bbsc_contribution_cache + contribute_value 
			where player_id = _parent_id;
		end if;
		
	ELSEIF change_type = 'tglb1' then
		update sczd_activity_info set tglb_contribution_for_parent = tglb_contribution_for_parent + contribute_value 
		where player_id = _player_id;
		
		if parent_active=0 then
			update sczd_activity_info set tglb_contribution_cache = tglb_contribution_cache + contribute_value 
			where player_id = _parent_id;
		end if;
	end if;
	
	insert into sczd_income_deatails_log(player_id,parent_id,treasure_type,treasure_value,is_active)
	values(_player_id,_parent_id,contribut_type,contribute_value,1);

	# 父亲的总获得值 增加
	update sczd_player_base_info set total_get_award = total_get_award + contribute_value 
			where player_id = _parent_id;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for daily_clearup_data
-- ----------------------------
DROP PROCEDURE IF EXISTS `daily_clearup_data`;
delimiter ;;
CREATE PROCEDURE `daily_clearup_data`()
  SQL SECURITY INVOKER
BEGIN


	-- 每天例行的数据清理

		declare last_day datetime;
		declare last_month datetime;
		declare last_week datetime;
		
		set last_day = DATE_ADD(now(),INTERVAL -1 DAY);
		set last_month = DATE_ADD(now(),INTERVAL -1 MONTH);
		set last_week = DATE_ADD(now(),INTERVAL -1 WEEK);
		
    start transaction;
    
    -- 登陆表：删除离线超过 7 天的（非活跃用户）
    delete from player_login where logout_time < last_week or (logout_time = null and login_time < last_week);
    
    -- 购物表：一个月前的数据移到日志表
    insert into player_shop_order_log(order_id,player_id,order_status,amount,shoping_desc,shoping_time,refund_time) 
    select order_id,player_id,order_status,amount,shoping_desc,shoping_time,refund_time from player_shop_order where shoping_time < last_month;
    delete from player_shop_order where shoping_time < last_month;
    
    -- 提现表：一天前且完成 的数据移到日志表
    insert into player_withdraw_log(withdraw_id,player_id,withdraw_status,error_desc,money,channel_type,channel_withdraw_id,channel_receiver_id,create_time,complete_time)
    select withdraw_id,player_id,withdraw_status,error_desc,money,channel_type,channel_withdraw_id,channel_receiver_id,create_time,complete_time from player_withdraw where withdraw_status='complete' and complete_time < last_day;
    delete from player_withdraw where withdraw_status='complete' and complete_time < last_day;
    
    -- 充值详情表：一个月前且完成 的数据移到日志表
    insert into player_pay_order_detail_log(order_id,asset_type,asset_count)
    select a.order_id,a.asset_type,a.asset_count from player_pay_order_detail a left join player_pay_order b on a.order_id = b.order_id
    where (b.order_status='complete' and b.end_time < last_month) or isnull(b.order_id);
    delete a from player_pay_order_detail a left join player_pay_order b on a.order_id = b.order_id
    where (b.order_status='complete' and b.end_time < last_month) or isnull(b.order_id);
    
    -- 充值表：一天前且完成 的数据移到日志表
    INSERT INTO `player_pay_order_log`
		(`order_id`,
		`player_id`,
		`order_status`,
		`error_desc`,
		`money_type`,
		`money`,
		`channel_type`,
		`channel_account_id`,
		`source_type`,
		`product_id`,
		`product_count`,
		`product_desc`,
		`is_test`,
		`create_time`,
		`channel_product_id`,
		`channel_order_id`,
		`itunes_trans_id`,
		`end_time`)
	SELECT `order_id`,
		`player_id`,
		`order_status`,
		`error_desc`,
		`money_type`,
		`money`,
		`channel_type`,
		`channel_account_id`,
		`source_type`,
		`product_id`,
		`product_count`,
		`product_desc`,
		`is_test`,
		`create_time`,
		`channel_product_id`,
		`channel_order_id`,
		`itunes_trans_id`,
		`end_time`
	FROM `player_pay_order`
	WHERE order_status='complete' and create_time < last_day;
	
    
    delete from player_pay_order WHERE order_status='complete' and create_time < last_day;
    
    commit;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for eachhour_clearup_data
-- ----------------------------
DROP PROCEDURE IF EXISTS `eachhour_clearup_data`;
delimiter ;;
CREATE PROCEDURE `eachhour_clearup_data`()
  SQL SECURITY INVOKER
BEGIN

	-- 处理 每小时（整点）要统计 清理的 数据 
    
    -- 俱乐部的玩家消费总计表，每次统计 1000 条
    declare last_log_id int;
    set last_log_id = get_variant_int('last_club_total_consume_stat_id');
    begin
		declare _log_id int;
		declare _player_id varchar(50);
        declare _asset_type varchar(50);
		declare _change_type varchar(50);
		declare _change_value bigint;
        DECLARE done INT DEFAULT FALSE;
        
        declare _cur_log_id int;
        
		declare log_cursor cursor for select log_id,id,asset_type,change_type,change_value from player_asset_log where log_id > if(isnull(last_log_id),0,last_log_id) limit 0,1000;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

        open log_cursor;
        log_cur_loop:loop
        
			fetch log_cursor into _log_id,_player_id,_asset_type,_change_type,_change_value;
            
			IF done THEN
				LEAVE log_cur_loop;
			END IF;           
            
            set _cur_log_id = _log_id;
            if _asset_type = 'diamond' then
            
				insert into club_total_consume(player_id,diamond,last_log_id) values(_player_id,_change_value,_log_id)
                on duplicate key update diamond=diamond+_change_value,last_log_id=_log_id;
                
			elseif _asset_type = 'shop_ticket' then
            
				insert into club_total_consume(player_id,shop_ticket,last_log_id) values(_player_id,_change_value,_log_id)
                on duplicate key update shop_ticket=shop_ticket+_change_value,last_log_id=_log_id;
                
			elseif _asset_type = 'cash' then
            
				insert into club_total_consume(player_id,cash,last_log_id) values(_player_id,_change_value,_log_id)
                on duplicate key update cash=cash+_change_value,last_log_id=_log_id;
                
			end if;
                        
            set done = false;
		end loop log_cur_loop;
        
        if not isnull(_cur_log_id) then
			insert into system_variant(`name`,`value`,`descript`) values ('last_club_total_consume_stat_id',_cur_log_id,'俱乐部系统已统计的消费日志')
            on duplicate key update `value` = _cur_log_id;
        end if;
    end;
    
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for gen_player_asset_refund
-- ----------------------------
DROP PROCEDURE IF EXISTS `gen_player_asset_refund`;
delimiter ;;
CREATE PROCEDURE `gen_player_asset_refund`()
  SQL SECURITY INVOKER
BEGIN

	-- 处理玩家 asset 财富的退款记录
    
		declare max_asset_refund_seq bigint;
		declare done int default 0;
        
        declare refund_max_time int default 900; -- 退款的最长时间，单位 秒
		
		declare tmp_log_id int;
		declare tmp_player_id varchar(50);
		declare tmp_date_sec int; -- 时间，秒
		declare tmp_asset_type varchar(50);
		declare tmp_change_value bigint;
		declare tmp_refund_change_type varchar(50);
		declare tmp_sync_seq bigint;
		declare tmp_change_type varchar(50);
		
		declare ins_log_id_consume int;
        
        declare last_refund_seq bigint;
        declare last_safe_seq bigint;
        
				
		DECLARE cur_asset CURSOR FOR select a.log_id,a.id,unix_timestamp(a.date),a.asset_type,a.change_value,a.change_type,a.sync_seq,b.change_type
							from player_asset_log a 
							inner join player_change_type_refund b on a.change_type=b.change_type_refund 
							where a.sync_seq > if(max_asset_refund_seq is null,0,max_asset_refund_seq)
							order by a.sync_seq limit 100;
		declare continue handler for not FOUND set done=1;
    
		-- 消费数据和退款数据配对：将退款和之前 n 分钟以内的 消费配对
		select max(seq_refund) into max_asset_refund_seq from player_asset_refund;
    
		open cur_asset;
		FETCH cur_asset INTO tmp_log_id,tmp_player_id,tmp_date_sec,tmp_asset_type,tmp_change_value,tmp_refund_change_type,tmp_sync_seq,tmp_change_type;
		while done <> 1 do
		
				-- 找对应的消费项目：往回找第一个匹配的
				select a.log_id into ins_log_id_consume from player_asset_log a 
				left join player_asset_refund b on a.log_id = b.log_id 
				where a.change_type = tmp_change_type and a.id=tmp_player_id and a.change_value = -tmp_change_value and a.sync_seq < tmp_sync_seq and b.log_id is null and (tmp_date_sec - unix_timestamp(a.date)) <= refund_max_time 
				order by a.date desc limit 1;
				
				if ins_log_id_consume is null then
						set done = 1;		-- 有异常：找不到对应消费项，不再继续
						insert into system_error(error_name,error_sn,error_info) 
						values('asset_log_refund',tmp_log_id,'退款未发现消费数据！') 
						on duplicate key update error_info = '退款未发现消费数据！';
				else
						insert into player_asset_refund(log_id,log_id_refund,seq_refund) values (ins_log_id_consume,tmp_log_id,tmp_sync_seq);
                        set last_refund_seq = tmp_sync_seq;
				end if;
				
				FETCH cur_asset INTO tmp_log_id,tmp_player_id,tmp_date_sec,tmp_asset_type,tmp_change_value,tmp_refund_change_type,tmp_sync_seq,tmp_change_type;		
		end while;
		close cur_asset;
        
        if last_refund_seq is null then
        
			-- 没有退款，则赋给限制时间前最大的
			select max(sync_seq) into last_safe_seq from player_asset_log where (unix_timestamp(now()) - unix_timestamp(`date`)) >= refund_max_time; 
		else
        
			-- 记录安全数据的 seq ：第一个未处理 退款前 n 分钟
			select unix_timestamp(a.date) into tmp_date_sec from player_asset_log a 
			inner join player_change_type_refund b on a.change_type=b.change_type_refund 
			where a.sync_seq > if(last_refund_seq is null,0,last_refund_seq) order by a.sync_seq limit 1; 
			
			if tmp_date_sec is null then
			
				-- 没有退款，则赋给限制时间前最大的
			
				select max(sync_seq) into last_safe_seq from player_asset_log where (unix_timestamp(now()) - unix_timestamp(`date`)) >= refund_max_time; 
			else
				select sync_seq into last_safe_seq from player_asset_log
				where tmp_date_sec - unix_timestamp(date) >= refund_max_time order by sync_seq desc limit 1; 
			end if;
            
		end if;
        
        if last_safe_seq is not null then
			insert into system_variant(`name`,`value`) values('last_asset_safe_seq',if(last_safe_seq is null,0,last_safe_seq)) 
			on duplicate key update `value` = if(last_safe_seq is null,0,last_safe_seq);
		end if;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for gen_player_prop_refund
-- ----------------------------
DROP PROCEDURE IF EXISTS `gen_player_prop_refund`;
delimiter ;;
CREATE PROCEDURE `gen_player_prop_refund`()
  SQL SECURITY INVOKER
BEGIN

	-- 处理玩家 prop 财富的退款记录
    
		declare max_prop_refund_seq bigint;
		declare done int default 0;
		
		declare tmp_log_id int;
		declare tmp_player_id varchar(50);
		declare tmp_date_sec int; -- 时间，秒
		declare tmp_prop_type varchar(50);
		declare tmp_change_value bigint;
		declare tmp_refund_change_type varchar(50);
		declare tmp_sync_seq bigint;
		declare tmp_change_type varchar(50);
		
		declare ins_log_id_consume int;
				
		DECLARE cur_prop CURSOR FOR select a.log_id,a.id,unix_timestamp(a.date),a.prop_type,a.change_value,a.change_type,a.shop_gold_sync_seq,b.change_type
							from player_prop_log a 
							inner join player_change_type_refund b on a.change_type=b.change_type_refund 
							where a.shop_gold_sync_seq > if(max_prop_refund_seq is null,0,max_prop_refund_seq)
							order by a.shop_gold_sync_seq limit 100;
		declare continue handler for not FOUND set done=1;
    
		-- 消费数据和退款数据配对：将退款和之前 n 分钟以内的 消费配对
		select max(seq_refund) into max_prop_refund_seq from player_prop_refund;
    
		open cur_prop;
		FETCH cur_prop INTO tmp_log_id,tmp_player_id,tmp_date_sec,tmp_prop_type,tmp_change_value,tmp_refund_change_type,tmp_sync_seq,tmp_change_type;
		while done <> 1 do
		
				-- 找对应的消费项目：往回找第一个匹配的
				select a.log_id into ins_log_id_consume from player_prop_log a 
				left join player_prop_refund b on a.log_id = b.log_id 
				where a.change_type = tmp_change_type and a.id=tmp_player_id and a.change_value = -tmp_change_value and a.shop_gold_sync_seq < tmp_sync_seq and b.log_id is null and tmp_date_sec - unix_timestamp(a.date) < 900 
				order by a.date desc limit 1;
				
				if ins_log_id_consume is null then
						set done = 1;		-- 有异常：找不到对应消费项，不再继续
						insert into system_error(error_name,error_sn,error_info) 
						values('prop_log_refund',tmp_log_id,'退款未发现消费数据！') 
						on duplicate key update error_info = '退款未发现消费数据！';
				else
						insert into player_prop_refund(log_id,log_id_refund,seq_refund) values (ins_log_id_consume,tmp_log_id,tmp_sync_seq);
				end if;
				
				FETCH cur_prop INTO tmp_log_id,tmp_player_id,tmp_date_sec,tmp_prop_type,tmp_change_value,tmp_refund_change_type,tmp_sync_seq,tmp_change_type;		
		end while;
		close cur_prop;	
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for get_sczd_all_son_main_info
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_sczd_all_son_main_info`;
delimiter ;;
CREATE PROCEDURE `get_sczd_all_son_main_info`(IN player_id VARCHAR(50))
BEGIN
  #Routine body goes here...
	select a.id,a.`name`,a.logined,ifnull(b.total_contribution_for_parent,0) my_all_gx,unix_timestamp(c.register_time) register_time, unix_timestamp(d.last_login_time) last_login_time 
		from player_info a left join sczd_player_base_info b on a.id = b.player_id
		left join player_register c on a.id = c.id
		left join player_login_stat d on a.id = d.id
		where a.id in (select id from sczd_relation_data where parent_id = player_id);
	
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for get_sczd_base_info
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_sczd_base_info`;
delimiter ;;
CREATE PROCEDURE `get_sczd_base_info`(IN _player_id varchar(50) 
	, IN _goods_id int
	, out _is_activate_profit TINYINT 
	, out _total_get_award int 
	, out _all_son_count int
	, out _is_active_tglb1_profit TINYINT
	, out _name varchar(50) 
	, out _logined TINYINT
	, out _my_all_gx int
	, out _register_time BIGINT
	, out _last_login_time BIGINT)
BEGIN
	#Routine body goes here...
	declare p_is_have_pay_order VARCHAR(50) DEFAULT '';
	declare p_is_activate_profit TINYINT DEFAULT 99;
	declare p_sczd_activity_data_num TINYINT DEFAULT 0;
	declare p_bbsc_data_num TINYINT DEFAULT 0;

	select is_activate_profit ,total_get_award ,all_son_count into p_is_activate_profit,_total_get_award,_all_son_count from sczd_player_base_info where player_id= _player_id;
	
	####
	select COUNT(*) into p_sczd_activity_data_num from sczd_activity_info WHERE player_id = _player_id;
	
	if p_sczd_activity_data_num = 0 then
		insert into sczd_activity_info(player_id,tglb_contribution_for_parent,bbsc_contribution_for_parent,tglb_contribution_cache,bbsc_contribution_cache) values(_player_id,0,0,0,0);
	end if;
	
	#### 步步生财数据
	select COUNT(*) into p_bbsc_data_num from player_stepstep_money WHERE player_id = _player_id;
	if p_bbsc_data_num = 0 then
		insert into player_stepstep_money(player_id,now_big_step,now_little_step,last_op_time,can_do_big_step) values(_player_id,1,1, UNIX_TIMESTAMP(NOW()) ,1);
	end if;
	
	# 没有数据，插入一条
	if p_is_activate_profit = 99 then
		insert into sczd_player_base_info(player_id,total_get_award,is_activate_profit,total_contribution_for_parent,all_son_count) values(_player_id,0,1,0,0);
		set p_is_activate_profit = 1;
		set _total_get_award = 0;
		set _all_son_count = 0;
	end if;
	set _is_activate_profit = p_is_activate_profit;
	
	select order_id into p_is_have_pay_order from player_pay_order where player_id = _player_id and product_id = _goods_id and order_status = 'complete' limit 1;
	
	
	if p_is_have_pay_order = '' or not p_is_have_pay_order then
		set _is_active_tglb1_profit = 0 ;
	else
		set _is_active_tglb1_profit = 1 ;
	end if;
	
	
	select a.`name`,a.logined,ifnull(b.total_contribution_for_parent,0),unix_timestamp(c.register_time), unix_timestamp(d.last_login_time)
				into _name,_logined,_my_all_gx,_register_time,_last_login_time
		from player_info a left join sczd_player_base_info b on a.id = b.player_id
		left join player_register c on a.id = c.id
		left join player_login_stat d on a.id = d.id
		where a.id = _player_id;
	
	#select _is_activate_profit,_total_get_award,_all_son_count,_is_active_tglb1_profit,_name,_logined,_my_all_gx,_register_time,_last_login_time;

END
;;
delimiter ;

-- ----------------------------
-- Function structure for get_variant_int
-- ----------------------------
DROP FUNCTION IF EXISTS `get_variant_int`;
delimiter ;;
CREATE FUNCTION `get_variant_int`(var_name varchar(100))
 RETURNS int(11)
  READS SQL DATA 
  SQL SECURITY INVOKER
BEGIN

	declare _value varchar(500);

	select value into _value from system_variant where name = var_name;
    
	RETURN CONVERT(_value,SIGNED);
END
;;
delimiter ;

-- ----------------------------
-- Function structure for get_variant_uint
-- ----------------------------
DROP FUNCTION IF EXISTS `get_variant_uint`;
delimiter ;;
CREATE FUNCTION `get_variant_uint`(var_name varchar(100))
 RETURNS int(10) unsigned
  READS SQL DATA 
  SQL SECURITY INVOKER
BEGIN
	declare _value varchar(500);

	select value into _value from system_variant where name = var_name;
    
	RETURN CONVERT(_value,UNSIGNED);
    
RETURN 1;
END
;;
delimiter ;

-- ----------------------------
-- Function structure for get_variant_varchar
-- ----------------------------
DROP FUNCTION IF EXISTS `get_variant_varchar`;
delimiter ;;
CREATE FUNCTION `get_variant_varchar`(var_name varchar(100))
 RETURNS varchar(500) CHARSET utf8
  READS SQL DATA 
  SQL SECURITY INVOKER
BEGIN

	declare _value varchar(500);

	select value into _value from system_variant where name = var_name;
    
	RETURN _value;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for init_club_info_data
-- ----------------------------
DROP PROCEDURE IF EXISTS `init_club_info_data`;
delimiter ;;
CREATE PROCEDURE `init_club_info_data`()
BEGIN
declare _index int;

SET @_player_id = '1010870';
SET @_parent_id = '1021748';
SET @_parent_ids = '1021748';
SET _index = 0;
repeat
	SET @_player_id = @_player_id + 1;
	

	INSERT INTO club_info(id,parent_id,parent_ids,is_tgy,is_agent) VALUES (@_player_id,@_parent_id,@_parent_ids,1,1);
	SET _index = _index + 1;
until _index > 100
end repeat;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for init_data
-- ----------------------------
DROP PROCEDURE IF EXISTS `init_data`;
delimiter ;;
CREATE PROCEDURE `init_data`()
BEGIN
declare _id int;
declare _index int;


SET @_player_id = 1010870;
SET @_payback_palyer_id = 1021830;
SET @_payback_value = 1000;
SET @_buy_vip_day = 10;
SET @_buy_time = 1507932000;
SET _id = 0;
SET _index = 0;
repeat
	SET _id = _id + 1;

	SET  @_buy_time =  @_buy_time + 86400;

	INSERT INTO player_vip_buy_record(id,player_id,payback_player_id,payback_value,buy_vip_day,buy_time,buy_time_year,buy_time_month,buy_time_day) 
	VALUES (_id,@_player_id, @_payback_palyer_id,@_payback_value ,@_buy_vip_day, @_buy_time , DATE_FORMAT(FROM_UNIXTIME(@_buy_time),'%Y') , DATE_FORMAT(FROM_UNIXTIME(@_buy_time),'%m') , DATE_FORMAT(FROM_UNIXTIME(@_buy_time),'%d') );
	SET _index = _index + 1;
until _index > 200
end repeat;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for init_vip_buy_record
-- ----------------------------
DROP PROCEDURE IF EXISTS `init_vip_buy_record`;
delimiter ;;
CREATE PROCEDURE `init_vip_buy_record`()
BEGIN
declare _id int;
declare _index int;


SET @_player_id = 1010870;
SET @_payback_palyer_id = 1022047;
SET @_payback_value = 1000;
SET @_buy_vip_day = 10;
SET @_buy_time = 1507932000;
SET _id = 203;
SET _index = 0;
repeat
	SET _id = _id + 1;

	SET  @_buy_time =  @_buy_time + 86400;

	INSERT INTO player_vip_buy_record(id,player_id,payback_player_id,payback_value,buy_vip_day,buy_time,buy_time_year,buy_time_month,buy_time_day) 
	VALUES (_id,@_player_id, @_payback_palyer_id,@_payback_value ,@_buy_vip_day, @_buy_time , DATE_FORMAT(FROM_UNIXTIME(@_buy_time),'%Y') , DATE_FORMAT(FROM_UNIXTIME(@_buy_time),'%m') , DATE_FORMAT(FROM_UNIXTIME(@_buy_time),'%d') );
	SET _index = _index + 1;
until _index > 1
end repeat;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for init_vip_extract_record
-- ----------------------------
DROP PROCEDURE IF EXISTS `init_vip_extract_record`;
delimiter ;;
CREATE PROCEDURE `init_vip_extract_record`()
BEGIN
declare _index int;


SET @_player_id = 1022047;
SET @_extract_value = 10;
SET @_extract_time = 1507932000;
SET _index = 0;
repeat

	SET  @_extract_time =  @_extract_time + 86400;

	INSERT INTO player_vip_generalize_extract_record(player_id,extract_value,extract_time) 
	VALUES (@_player_id, @_extract_value,@_extract_time );
	SET _index = _index + 1;
until _index > 1
end repeat;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for minute5_clear_data
-- ----------------------------
DROP PROCEDURE IF EXISTS `minute5_clear_data`;
delimiter ;;
CREATE PROCEDURE `minute5_clear_data`()
  SQL SECURITY INVOKER
BEGIN

	-- 每5分钟处理的数据清理（程序中还没 加调用）
    
		
		
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for minute_clear_data
-- ----------------------------
DROP PROCEDURE IF EXISTS `minute_clear_data`;
delimiter ;;
CREATE PROCEDURE `minute_clear_data`()
  SQL SECURITY INVOKER
BEGIN

	-- 每分钟处理的数据清理
    
    -- 财富 退款
	call gen_player_asset_refund();
    call gen_player_prop_refund();
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for query_city_match_info
-- ----------------------------
DROP PROCEDURE IF EXISTS `query_city_match_info`;
delimiter ;;
CREATE PROCEDURE `query_city_match_info`()
BEGIN

	SET @hx_join_num = 0;
	SET @hx_promoted_num = 0;
	SET @hx_lose_num = 0;

	SET @fs_join_num = 0;
	SET @fs_promoted_num = 0;
	SET @fs_lose_num = 0;
	SET @baoming_count = 0;

	SELECT COUNT(*) into @hx_lose_num FROM zy_city_match_hx_lose WHERE player_id NOT LIKE "v%";
	SELECT COUNT(*) into @hx_promoted_num FROM zy_city_match_rank_hx WHERE player_id NOT LIKE "v%";
	SELECT @hx_lose_num + @hx_promoted_num INTO @hx_join_num;

	SELECT COUNT(*) into @fs_lose_num FROM zy_city_match_fs_lose WHERE player_id NOT LIKE "v%";
	SELECT COUNT(*) into @fs_promoted_num FROM zy_city_match_rank_fs WHERE player_id NOT LIKE "v%";
	SELECT @fs_lose_num + @fs_promoted_num INTO @fs_join_num;
	
	SELECT -sum(change_value) into @baoming_count FROM player_prop_log where change_type in ('match_signup','match_cancel_signup') and prop_type='zy_city_match_ticket_hx';
	
	SELECT 
	@hx_join_num as "海选总参与人数",
	@hx_promoted_num as "海选晋级人数",
	@hx_lose_num as "海选失败人数",
	@fs_join_num as "复赛参与人数",
	@fs_promoted_num as "复赛晋级人数",
	@fs_lose_num as "复赛失败人数",
	@baoming_count as "海选报名次数";


	SELECT * FROM zy_city_match_hx_lose WHERE player_id NOT LIKE "v%";
	SELECT * FROM zy_city_match_rank_hx WHERE player_id NOT LIKE "v%";

	SELECT * FROM zy_city_match_fs_lose WHERE player_id NOT LIKE "v%";
	SELECT * FROM zy_city_match_rank_fs WHERE player_id NOT LIKE "v%";

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for query_nor_ddz_nor_race_log_operation
-- ----------------------------
DROP PROCEDURE IF EXISTS `query_nor_ddz_nor_race_log_operation`;
delimiter ;;
CREATE PROCEDURE `query_nor_ddz_nor_race_log_operation`(`race_id` int)
BEGIN

	SET @opts = "";

	SELECT operation_list into @opts FROM nor_ddz_nor_race_log WHERE id=race_id;

	SET @size = LENGTH(@opts);  
	SET @pos = 1;  
	SET @str = "";

	WHILE @pos<@size+1 DO  
					SET @c = SUBSTRING(@opts,@pos,1);
					SET @str = CONCAT(@str,",",ASCII(@c));
					SET @pos = @pos + 1;
	END WHILE; 
	
	SELECT @str;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for query_nor_mj_xzdd_race_log_operation
-- ----------------------------
DROP PROCEDURE IF EXISTS `query_nor_mj_xzdd_race_log_operation`;
delimiter ;;
CREATE PROCEDURE `query_nor_mj_xzdd_race_log_operation`(`race_id` int)
BEGIN

	SET @opts = "";

	SELECT operation_list into @opts FROM nor_mj_xzdd_race_log WHERE id=race_id;

	SET @size = LENGTH(@opts);  
	SET @pos = 1;  
	SET @str = "";

	WHILE @pos<@size+1 DO  
					SET @c = SUBSTRING(@opts,@pos,1);
					SET @str = CONCAT(@str,",",ASCII(@c));
					SET @pos = @pos + 1;
	END WHILE; 
	
	SELECT @str;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for sczd_activate_tglb
-- ----------------------------
DROP PROCEDURE IF EXISTS `sczd_activate_tglb`;
delimiter ;;
CREATE PROCEDURE `sczd_activate_tglb`(IN _player_id varchar(50)
	,OUT _tglb_award_cache int)
BEGIN
	#Routine body goes here...

	-- declare p_tglb_award_cache int;
	
	select tglb_contribution_cache into _tglb_award_cache from sczd_activity_info where player_id = _player_id;

	-- set _tglb_award_cache = p_tglb_award_cache;
	-- select _tglb_award_cache;

	update sczd_activity_info set tglb_contribution_cache = 0 where player_id = _player_id;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for sczd_change_parent
-- ----------------------------
DROP PROCEDURE IF EXISTS `sczd_change_parent`;
delimiter ;;
CREATE PROCEDURE `sczd_change_parent`(IN _player_id VARCHAR(50) 
, IN _new_parent_id VARCHAR(50))
BEGIN
  #Routine body goes here...
	
	DECLARE old_parent_id VARCHAR(50) DEFAULT '';
	# 找旧上级
	SELECT parent_id into old_parent_id FROM sczd_relation_data WHERE id = _player_id;
	# 旧上级，son数量-1
	if old_parent_id and old_parent_id <> '' then
		UPDATE sczd_player_base_info SET all_son_count = all_son_count - 1 where player_id = old_parent_id;
	end if;	
	# 更新关系
	update sczd_relation_data set parent_id = _new_parent_id where id = _player_id;
	# 新上级，son数量+1
	UPDATE sczd_player_base_info SET all_son_count = all_son_count + 1 where player_id = _new_parent_id;
	# 我的总贡献清0
	update sczd_player_base_info set total_contribution_for_parent = 0 where player_id = _player_id;
	# 我的其他贡献 清0
	update sczd_activity_info set tglb_contribution_for_parent = 0,bbsc_contribution_for_parent = 0 where player_id = _player_id;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for sczd_gjhhr_record_today_achievements
-- ----------------------------
DROP PROCEDURE IF EXISTS `sczd_gjhhr_record_today_achievements`;
delimiter ;;
CREATE PROCEDURE `sczd_gjhhr_record_today_achievements`()
BEGIN

		declare _now datetime;

		start transaction;

		set _now = now();

		insert into sczd_player_day_achievements_log(id,achievements,tuikuan,all_achievements,all_tuikuan,time)
		select id,all_achievements-yesterday_all_achievements,tuikuan-yesterday_tuikuan,all_achievements,tuikuan,_now 
		from sczd_player_all_achievements 
		where all_achievements <> yesterday_all_achievements or tuikuan <> yesterday_tuikuan;

		update sczd_player_all_achievements set yesterday_all_achievements = all_achievements,yesterday_tuikuan=tuikuan;

		commit;	

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for sp_login
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_login`;
delimiter ;;
CREATE PROCEDURE `sp_login`(id varchar(50),

	login_ip varchar(50),

	login_os varchar(500))
  SQL SECURITY INVOKER
BEGIN
 
	start transaction;

 
	insert into player_login_log(id,login_ip,login_os) values(id,login_ip,login_os);

	insert into player_login(id,login_ip,login_os,on_line,log_id) values(id,login_ip,login_os,1,last_insert_id())
  on duplicate key update login_ip = login_ip,login_os=login_os,log_id = last_insert_id(),on_line=1,login_time = now(),logout_time=null;
       
	insert into player_login_stat(id,first_login_time,first_log_id,last_login_time,last_log_id) values(id,now(),last_insert_id(),now(),last_insert_id())
  on duplicate key update last_login_time = now(),last_log_id=last_insert_id();

  commit;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for sp_logout
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_logout`;
delimiter ;;
CREATE PROCEDURE `sp_logout`(_ID varchar(50))
  SQL SECURITY INVOKER
BEGIN
    declare _log_id INT;
    
	start transaction;
    
    select log_id into _log_id from player_login where id = _ID and on_line=1 ;
    if FOUND_ROWS() > 0 then
		update player_login_log set logout_time = now() where log_id = _log_id;
		update player_login set logout_time = now(),on_line=NULL where id = _ID;
	end if;
        
    commit;
END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
