#!/usr/bin/perl -w

# Split an excel file into multiple csv files (one csv per worksheet)
# Right now this is for a very special usecase: only the first column in each sheet will be copied to the csv)

use strict;
use Spreadsheet::ParseExcel;

my $parser = Spreadsheet::ParseExcel->new();
print "Opening xls\n";
my $workbook = $parser->parse ( 'input.xls' );

print "Working through workbooks\n";
for my $worksheet ( $workbook->worksheets() ) {
	my $sheetname = $worksheet->get_name();
	$sheetname =~ s/[^a-zA-Z0-9-_]//g;
	$sheetname = lc($sheetname);
	print "Sheet $sheetname\n";

	my $has_data = 1;
	my $row_no = 0;

	open(OUT, '>'.$sheetname.'.csv');

	while( $has_data ) {
		my $cell = $worksheet->get_cell( $row_no, 0 );
		$row_no++;
		if ($cell) { print OUT lc($cell->value)."\n"; }

		$has_data = ($cell && $cell->value ne "");
	}

	close(OUT);
}
		
