CREATE TABLE IF NOT EXISTS querys (
  title varchar(100) NOT NULL default '',
  description text NOT NULL,
  `sql` text NOT NULL,
  `return` varchar(100) NOT NULL default 'fetch_array',
  `id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;