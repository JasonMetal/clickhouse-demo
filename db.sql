-- 建表：
CREATE TABLE game_user_behavior
(
    user_id       UInt64,
    game_id       UInt32,
    behavior_type String,
    behavior_time DateTime,
    amount        Decimal(20, 7), -- 金额（分）：99.90元 → 9990
    level         UInt8,
    channel       String
) ENGINE = MergeTree()
ORDER BY (user_id, behavior_time);


-- TRUNCATE TABLE game_user_behavior;
--
--
-- -- 第一步：添加 amount 字段（先确保字段存在）
-- ALTER TABLE game_user_behavior
--     ADD COLUMN IF NOT EXISTS amount Decimal (20,7) AFTER behavior_time;

DESCRIBE TABLE game_user_behavior;

INSERT INTO game_user_behavior
VALUES (10001, 101, 'recharge', '2025-01-15 09:10:00', 99.9000000, 15, 'wechat'),
       (10002, 101, 'recharge', '2025-01-15 10:20:00', 100.0000000, 21, 'douyin'),
       (10003, 102, 'recharge', '2025-01-15 11:00:00', 199.9900000, 10, 'official'),
       (10001, 101, 'login', '2025-01-15 08:30:00', 0.0000000, 15, 'wechat'),
       (10002, 101, 'pass_level', '2025-01-15 10:20:00', 0.0000000, 21, 'douyin');


-- 验证插入结果
SELECT user_id, level, channel
FROM game_user_behavior
WHERE user_id IN (10001, 10002, 10003);


-- 单条插入测试（最简格式）
INSERT INTO game_user_behavior VALUES (10001, 101, 'recharge', '2025-01-15 09:10:00', 99.9000000, 15, 'wechat');

-- 验证插入/更新结果
SELECT user_id, amount, channel FROM game_user_behavior WHERE user_id IN (10001, 10002);

-- 验证删除结果
SELECT COUNT(*) FROM game_user_behavior WHERE user_id = 10004; -- 结果应为0


-- 1. 单条删除：用户10004的充值记录
ALTER TABLE game_user_behavior
DELETE WHERE
        user_id = 10004
         AND behavior_type = 'recharge';

-- 2. 批量删除：2025-01-15 金额小于50的充值记录
ALTER TABLE game_user_behavior
DELETE WHERE
        behavior_type = 'recharge'
         AND amount < 50.0000000
         AND behavior_time = '2025-01-15';

-- 3. 删除整分区数据（高效，推荐）：删除2025年1月的所有数据
ALTER TABLE game_user_behavior
DROP PARTITION 202501;


    -- 1. 单条更新：修正用户10001的充值金额
ALTER TABLE game_user_behavior
UPDATE
    amount = 109.9000000,  -- 匹配Decimal(20,7)格式
    level = 16             -- 同时更新等级
WHERE
    user_id = 10001
  AND behavior_type = 'recharge'
  AND behavior_time = '2025-01-15 09:10:00';

-- 2. 批量更新：抖音渠道所有充值记录金额+10元
ALTER TABLE game_user_behavior
UPDATE amount = amount + 10.0000000
WHERE
    behavior_type = 'recharge'
  AND channel = 'douyin';

-- 3. 更新非金额字段：修改用户10002的渠道
ALTER TABLE game_user_behavior
UPDATE channel = 'wechat'
WHERE user_id = 10002 AND game_id = 101;


-- 1. 基础查询：所有数据
SELECT * FROM game_user_behavior;

-- 2. 条件查询：2025-01-15 微信渠道的充值记录
SELECT
    user_id,
    game_id,
    amount,
    behavior_time,
    channel
FROM game_user_behavior
WHERE
        behavior_type = 'recharge'
  AND channel = 'wechat'
  AND behavior_time = '2025-01-15';

-- 3. 排序+分页：充值金额降序，取前3条
SELECT
    user_id,
    amount,
    behavior_time
FROM game_user_behavior
WHERE behavior_type = 'recharge'
ORDER BY amount DESC
    LIMIT 3 OFFSET 0;

-- 4. 聚合查询：按游戏ID统计充值总额/平均金额/充值用户数
SELECT
    game_id,
    SUM(amount) AS total_recharge,       -- 总充值（Decimal类型）
    AVG(amount) AS avg_recharge,         -- 平均充值（Decimal类型）
    COUNT(DISTINCT user_id) AS user_cnt  -- 充值用户数
FROM game_user_behavior
WHERE behavior_type = 'recharge'
GROUP BY game_id;

-- 5. 时间维度聚合：按小时统计充值金额
SELECT
    toHour(behavior_time) AS hour,
    SUM(amount) AS hour_recharge
FROM game_user_behavior
WHERE
    behavior_type = 'recharge'
  AND behavior_time BETWEEN '2025-01-15 00:00:00' AND '2025-01-15 23:59:59'
GROUP BY hour
ORDER BY hour;

-- 6. Decimal 精准筛选：金额大于100的充值记录
SELECT user_id, amount
FROM game_user_behavior
WHERE behavior_type = 'recharge' AND amount > 100.0000000;