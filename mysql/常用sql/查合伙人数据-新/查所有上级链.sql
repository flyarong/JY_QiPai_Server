
select concat(a.player_id,' (',b.`name`,')') `我`,
	if('0' = a.parent_1,'',concat(a.parent_1,' (',b1.`name`,')'))  `上级1`,
	if('0' = a.parent_2,'',concat(a.parent_2,' (',b2.`name`,')'))  `上级2`,
	if('0' = a.parent_3,'',concat(a.parent_3,' (',b3.`name`,')'))  `上级3`,
	if('0' = a.parent_4,'',concat(a.parent_4,' (',b4.`name`,')'))  `上级4`,
	if('0' = a.parent_5,'',concat(a.parent_5,' (',b5.`name`,')'))  `上级5`,
	if('0' = a.parent_6,'',concat(a.parent_6,' (',b6.`name`,')'))  `上级6`,
	if('0' = a.parent_7,'',concat(a.parent_7,' (',b7.`name`,')'))  `上级7`,
	if('0' = a.parent_8,'',concat(a.parent_8,' (',b8.`name`,')'))  `上级8`,
	if('0' = a.parent_9,'',concat(a.parent_9,' (',b9.`name`,')'))  `上级9`,
	if('0' = a.parent_10,'',concat(a.parent_10,' (',b10.`name`,')'))  `上级10`,
	if('0' = a.parent_11,'',concat(a.parent_11,' (',b11.`name`,')'))  `上级11`,
	if('0' = a.parent_12,'',concat(a.parent_12,' (',b12.`name`,')'))  `上级12`,
	if('0' = a.parent_13,'',concat(a.parent_13,' (',b13.`name`,')'))  `上级13`,
	if('0' = a.parent_14,'',concat(a.parent_14,' (',b14.`name`,')'))  `上级14`,
	if('0' = a.parent_15,'',concat(a.parent_15,' (',b15.`name`,')'))  `上级15`,
	if('0' = a.parent_16,'',concat(a.parent_16,' (',b16.`name`,')'))  `上级16`,
	if('0' = a.parent_17,'',concat(a.parent_17,' (',b17.`name`,')'))  `上级17`,
	if('0' = a.parent_18,'',concat(a.parent_18,' (',b18.`name`,')'))  `上级18`,
	if('0' = a.parent_19,'',concat(a.parent_19,' (',b19.`name`,')'))  `上级19`,
	if('0' = a.parent_20,'',concat(a.parent_20,' (',b20.`name`,')'))  `上级20`,
	if('0' = a.parent_21,'',concat(a.parent_21,' (',b21.`name`,')'))  `上级21`
	
from player_ancestor a
inner join player_info b on a.player_id = b.id
inner join player_info b1 on a.parent_1 = b1.id
inner join player_info b2 on a.parent_2 = b2.id
inner join player_info b3 on a.parent_3 = b3.id
inner join player_info b4 on a.parent_4 = b4.id
inner join player_info b5 on a.parent_5 = b5.id
inner join player_info b6 on a.parent_6 = b6.id
inner join player_info b7 on a.parent_7 = b7.id
inner join player_info b8 on a.parent_8 = b8.id
inner join player_info b9 on a.parent_9 = b9.id
inner join player_info b10 on a.parent_10 = b10.id
inner join player_info b11 on a.parent_11 = b11.id
inner join player_info b12 on a.parent_12 = b12.id
inner join player_info b13 on a.parent_13 = b13.id
inner join player_info b14 on a.parent_14 = b14.id
inner join player_info b15 on a.parent_15 = b15.id
inner join player_info b16 on a.parent_16 = b16.id
inner join player_info b17 on a.parent_17 = b17.id
inner join player_info b18 on a.parent_18 = b18.id
inner join player_info b19 on a.parent_19 = b19.id
inner join player_info b20 on a.parent_20 = b20.id
inner join player_info b21 on a.parent_21 = b21.id

