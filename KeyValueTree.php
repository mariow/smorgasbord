<?php

/*

KeyValueTree.pm - a quick module to store data in multiple files across a directory tree

SYNOPSIS

  Setup:
  use KeyValueTree;
  my $kvt = KeyValueTree->new( PATH => '/tmp/kvt/' );
  (make sure that /tmp/kvt includes a file "kvt.path" and that it is otherwise empty)

  Basic usage:
  $kvt->set("key", "value");
  my $value = $kvt->get("key");

DESCRIPTION

KeyValueTree is a quick solution to store a lot of small Key-Value pairs in a directory tree. The idea was to get small files and directories that are still usable (not filled with thousands of files).

AUTHOR

Mario Witte, <mario.witte@chengfu.net>

COPYRIGHT

Copyright 2013 by  Mario Witte

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.

*/

class KeyValueTree {
	public $path = '';
	private $created = 0;

	function __construct($path) {
		if (!file_exists($path) or !is_executable($path)) { throw new Exception($path.' does not exist or is not accessible'); }

		$this->created = 1;
		$this->path = preg_replace('/\/+$/', '', $path);
		$this->path.= '/';

		if (!file_exists($this->path.'kvt.path')) { throw new Exception($this->path.'kvt.path does not exist'); }
	}

	public function get($key) {
		$key = $this->_valid_key($key);
		if ($key == '') { throw new Exception('invalid key ('.$key.') in get'); }

		$path = $this->_path_for_key($key);

		$data_path = $this->path.$path;
		if (is_readable($data_path)) {
			$fh = fopen($data_path, 'r');
			$ip = '';
			while(!feof($fh) && $ip == '') {
				$line = fgets($fh, 1024);
				if (preg_match('/^'.$key.'\t([0-9.]{7,15})$/', $line, $matches)) {
					$ip = $matches[1];
					continue;
				}
			}
			return $ip;
		}
	}

	public function set($key, $value) {
		$key = $this->_valid_key($key);
		if ($key == '') { throw new Exception('invalid key ('.$key.') in set'); }

		$path = $this->_path_for_key($key);
	
		# create path unless it exists
		if (!file_exists($this->path.$path)) { $this->_mkdir_recursive($path); }

		$tmpfile = tmpfile();
		$fhin = fopen($this->path.$path, 'r');
		$is_new_record = 1;
		$record_line = $key."\t".$value."\n";
		while (!feof($fhin)) {
			$line = fgets($fhin, 1024);
			if (preg_match('/^'.$key.'\t([0-9.]{7,15})$/', $line, $matches)) {
				$is_new_record = 0;
				$line = $record_line;
			}
			fputs($tmpfile, $line);
		}
		if ($is_new_record) { fputs($tmpfile, $record_line); }
			
		fclose($fhin);
		
		# Copy tmpfile to old filename
		$fhout = fopen($this->path.$path, 'w');
		rewind($tmpfile);
		while (($buffer = fgets($tmpfile, 4096)) !== false) {
			fputs($fhout, $buffer);
		}
		fclose($tmpfile);
		fclose($fhout);
	}

	private function _mkdir_recursive($path) {
		# separate file from dir path
		$dir_path = $path;
		if (preg_match('/^[a-z0-9_]{1,3}\.stor$/', $dir_path)) { return; }
		$dir_path = preg_replace('/\/[a-z0-9_]{1,3}\.stor$/', '', $dir_path);

		if ($dir_path != '') {
			mkdir($dir_path, 0777, true);
		}
	}
			
	private function _valid_key($key) {
		$key = strtolower($key);
		$key = preg_replace('/[^a-z0-9.-]/', '-', $key);
		if (!preg_match('/^[a-z0-9.-]{4,100}$/', $key)) {
			return '';
		}

		$key = str_replace('.', '_', $key);

		return $key;
	}

	private function _path_for_key($key) {
		$key = preg_replace('/[^a-z0-9]/', '', $key);
		$key_arr = str_split($key);

		$path = '';
		for ($i = 0; $i < 2 and sizeof($key_arr) > 0; $i++) {
			$path .= array_shift($key_arr);
			if (sizeof($key_arr) >= 0) { $path .= array_shift($key_arr); }
			$path .= '/';
		}
		$path = preg_replace('/\/$/', '.stor', $path);

		return $path;
	}
}
