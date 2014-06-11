use v5.10;
do 'data.def';
use Data::Dumper;

my @uldata_dec;
my $index = 0;

#my @data = @uldata::wcdmauldata;
my @data = @uldata::lte1uldata;

foreach (@data) {
	$uldata_dec[ $index++ ] = hex;
}

our $sample = \@uldata_dec;

my $wcdmaargs = {
	ratType       => 3,
	sigGenPower   => $_sig_gen_power,
	extGain       => $external_ul_gains[0],
	carrierOffset => 0,
	iqDataFormat  => '7bit30Axc'
};

my $lteargs = {
	ratType       => 1,
	sigGenPower   => -70,
	extGain       => 0,
	carrierOffset => 1,
	freq          => 1727400,
	bw            => 1400,
	rfPort        => 0,
	reportedGain  => 155.4,
};

checkUlIqData($lteargs);

sub processUlData {
	my $ulData = shift;

	%ulDataHeader = ();
	@ulDataBuffer = ();

	say("\n====================================================");
	say("Processing UL data received from RUMA");

	my $initial_chars = chr( $ulData->[0] ) . chr( $ulData->[1] ) . chr( $ulData->[2] ) . chr( $ulData->[3] );

	if ( $initial_chars eq ".ccu" ) {
		say("Detected CCU format");
		processCcuData($ulData);
	}

}

sub processCcuData {
	my $ulData = shift;

	%ulDataHeader = ();
	@ulDataBuffer = ();

	say("====================================================");
	say("Processing CCU data");

	$ulDataHeader{'type'}              = chr( $ulData->[0] ) . chr( $ulData->[1] ) . chr( $ulData->[2] ) . chr( $ulData->[3] );
	$ulDataHeader{'version'}           = ( $ulData->[4] << 24 ) | ( $ulData->[5] << 16 ) | ( $ulData->[6] << 8 ) | $ulData->[7];
	$ulDataHeader{'headerSize'}        = ( $ulData->[8] << 24 ) | ( $ulData->[9] << 16 ) | ( $ulData->[10] << 8 ) | $ulData->[11];
	$ulDataHeader{'fileSize'}          = ( $ulData->[12] << 24 ) | ( $ulData->[13] << 16 ) | ( $ulData->[14] << 8 ) | $ulData->[15];
	$ulDataHeader{'ms'}                = ( $ulData->[16] << 24 ) | ( $ulData->[17] << 16 ) | ( $ulData->[18] << 8 ) | $ulData->[19];
	$ulDataHeader{'s'}                 = ( $ulData->[20] << 24 ) | ( $ulData->[21] << 16 ) | ( $ulData->[22] << 8 ) | $ulData->[23];
	$ulDataHeader{'min'}               = ( $ulData->[24] << 24 ) | ( $ulData->[25] << 16 ) | ( $ulData->[26] << 8 ) | $ulData->[27];
	$ulDataHeader{'h'}                 = ( $ulData->[28] << 24 ) | ( $ulData->[29] << 16 ) | ( $ulData->[30] << 8 ) | $ulData->[31];
	$ulDataHeader{'dd'}                = ( $ulData->[32] << 24 ) | ( $ulData->[33] << 16 ) | ( $ulData->[34] << 8 ) | $ulData->[35];
	$ulDataHeader{'mm'}                = ( $ulData->[36] << 24 ) | ( $ulData->[37] << 16 ) | ( $ulData->[38] << 8 ) | $ulData->[39];
	$ulDataHeader{'yy'}                = ( $ulData->[40] << 24 ) | ( $ulData->[41] << 16 ) | ( $ulData->[42] << 8 ) | $ulData->[43];
	$ulDataHeader{'fileAttributes'}    = ( $ulData->[44] << 24 ) | ( $ulData->[45] << 16 ) | ( $ulData->[46] << 8 ) | $ulData->[47];
	$ulDataHeader{'carrierHeaderSize'} = ( $ulData->[48] << 24 ) | ( $ulData->[49] << 16 ) | ( $ulData->[50] << 8 ) | $ulData->[51];
	$ulDataHeader{'noOfCarriers'}      = ( $ulData->[52] << 24 ) | ( $ulData->[53] << 16 ) | ( $ulData->[54] << 8 ) | $ulData->[55];
	$ulDataHeader{'dataSize'}          = ( $ulData->[56] << 24 ) | ( $ulData->[57] << 16 ) | ( $ulData->[58] << 8 ) | $ulData->[59];
	$ulDataHeader{'various4'}          = ( $ulData->[60] << 24 ) | ( $ulData->[61] << 16 ) | ( $ulData->[62] << 8 ) | $ulData->[63];

	#_printHex($ulData, 0, $ulDataHeader{ 'fileSize' });

	$ulDataHeader{'comment'} = "";
	for ( my $i = 64 ; $i < 128 ; $i++ ) {
		$ulDataHeader{'comment'} = $ulDataHeader{'comment'} . chr( $ulData->[$i] );
	}

	my $index               = 128;                                  # Start of carrier headers section
	my $carrier_header_size = $ulDataHeader{'carrierHeaderSize'};
	my $no_of_carriers      = $ulDataHeader{'noOfCarriers'};
	my $carrier_headers     = [];
	if ( $carrier_header_size == 32 ) {
		for ( my $i = 0 ; $i < $no_of_carriers ; $i++ ) {
			my $carrier_header = {};
			$carrier_header->{'carrierId'} = ( $ulData->[$index] << 24 ) | ( $ulData->[ $index + 1 ] << 16 ) | ( $ulData->[ $index + 2 ] << 8 ) | $ulData->[ $index + 3 ];
			$index += 4;
			$carrier_header->{'axcStartContainer'} = ( $ulData->[$index] << 24 ) | ( $ulData->[ $index + 1 ] << 16 ) | ( $ulData->[ $index + 2 ] << 8 ) | $ulData->[ $index + 3 ];
			$index += 4;
			$carrier_header->{'axcContainerGroupLength'} = ( $ulData->[$index] << 24 ) | ( $ulData->[ $index + 1 ] << 16 ) | ( $ulData->[ $index + 2 ] << 8 ) | $ulData->[ $index + 3 ];
			$index += 4;
			$carrier_header->{'bfPeriod'} = ( $ulData->[$index] << 24 ) | ( $ulData->[ $index + 1 ] << 16 ) | ( $ulData->[ $index + 2 ] << 8 ) | $ulData->[ $index + 3 ];
			$index += 4;
			$carrier_header->{'technology'} = ( $ulData->[$index] << 24 ) | ( $ulData->[ $index + 1 ] << 16 ) | ( $ulData->[ $index + 2 ] << 8 ) | $ulData->[ $index + 3 ];
			$index += 4;
			$carrier_header->{'fsInfoBf'} = ( $ulData->[$index] << 24 ) | ( $ulData->[ $index + 1 ] << 16 ) | ( $ulData->[ $index + 2 ] << 8 ) | $ulData->[ $index + 3 ];
			$index += 4;
			$carrier_header->{'fsInfoHf'} = ( $ulData->[$index] << 24 ) | ( $ulData->[ $index + 1 ] << 16 ) | ( $ulData->[ $index + 2 ] << 8 ) | $ulData->[ $index + 3 ];
			$index += 4;
			$carrier_header->{'noOfAxcContainers'} = ( $ulData->[$index] << 24 ) | ( $ulData->[ $index + 1 ] << 16 ) | ( $ulData->[ $index + 2 ] << 8 ) | $ulData->[ $index + 3 ];
			$index += 4;
			push @$carrier_headers, $carrier_header;
		}

		$ulDataHeader{'carrierHeaders'} = $carrier_headers;
	} else {
		say("ERROR - Unexpected Carrier Header size: $carrier_header_size");
	}

	if ( $index != ( 128 + $no_of_carriers * $carrier_header_size ) ) {
		say("ERROR - Unexpected Header size: $index Expected: (128 + $no_of_carriers * $carrier_header_size)");
	}

	$index = ( 128 + $no_of_carriers * $carrier_header_size );

	while ( defined( $ulData->[ $index + 3 ] ) ) {
		my $data = ( $ulData->[$index] << 24 ) | ( $ulData->[ $index + 1 ] << 16 ) | ( $ulData->[ $index + 2 ] << 8 ) | $ulData->[ $index + 3 ];
		if ( $data >= 0x04000000 ) {
			$data -= 0x08000000;
		}
		push @ulDataBuffer, $data;
		$index = $index + 4;
	}
	_printCcuHeader( \%ulDataHeader );

}

sub _printHex {
	my $buf      = shift;
	my $startIdx = shift;
	my $length   = shift;
	say("(Printing $length hex bytes at index $startIdx:)");
	for ( my $idx = $startIdx ; $idx < $startIdx + $length ; $idx += 4 ) {
		my $rangeEnd = $idx + 3;
		my $str = sprintf "%02X %02X %02X %02X", $buf->[$idx], $buf->[ $idx + 1 ], $buf->[ $idx + 2 ], $buf->[ $idx + 3 ];
		say("($idx-$rangeEnd): $str");
	}
}

sub _printCcuHeader {
	my $ulDataHeader = shift;
	say("====================================================\n");
	if ( $ulDataHeader->{'type'} eq ".ccu" ) {
		say("CCU format");
	} else {
		say("Unknown format $ulDataHeader->{'type'}");
	}
	say("Format version: $ulDataHeader{ 'version' }");
	say("Header size: $ulDataHeader{ 'headerSize' }");
	say("File size: $ulDataHeader{ 'fileSize' }");
	say(    "Time: $ulDataHeader{ 'yy' }-"
		  . "$ulDataHeader{ 'mm' }-"
		  . "$ulDataHeader{ 'dd' }-"
		  . "$ulDataHeader{ 'h' }:"
		  . "$ulDataHeader{ 'min' }:"
		  . "$ulDataHeader{ 's' }."
		  . "$ulDataHeader{ 'ms' }" );
	say("File access: $ulDataHeader{ 'fileAttributes' }");
	say("Carrier header size: $ulDataHeader{ 'carrierHeaderSize' }");
	say("No of carriers: $ulDataHeader{ 'noOfCarriers' }");
	say("Data size: $ulDataHeader{ 'dataSize' }");
	say("Reserved bytes[4]: $ulDataHeader{ 'various4' }");
	say("User comment: $ulDataHeader{ 'comment' }");
	say("Carrier Headers:");
	my $no_of_carriers = $ulDataHeader{'noOfCarriers'};

	for ( my $i = 0 ; $i < $no_of_carriers ; $i++ ) {
		my $carrier_header = $ulDataHeader{'carrierHeaders'}->[$i];
		if ( !_isEmptyCcuCarrierHeader($carrier_header) ) {
			say("Carrier ID: $carrier_header->{ 'carrierId' }");
			say("\tAxC start container: $carrier_header->{ 'axcStartContainer' }");
			say("\tAxC container group length: $carrier_header->{ 'axcContainerGroupLength' }");
			say("\tBF period: $carrier_header->{ 'bfPeriod' }");
			say("\tTechnology: $carrier_header->{ 'technology' }");
			say("\tFS Info BF: $carrier_header->{ 'fsInfoBf' }");
			say("\tFS Info HF: $carrier_header->{ 'fsInfoHf' }");
			say("\tNo of AxC containers: $carrier_header->{ 'noOfAxcContainers' }");
		} else {

			#say( "Skip empty carrier header at position: $i" );
		}
	}
	say("====================================================\n");
}

#----------------------------------------------------------------
# Name: _isEmptyCcuCarrierHeader
# Description: Prints the CCU Carrier header is all zero
#
#----------------------------------------------------------------

sub _isEmptyCcuCarrierHeader {
	my $ccuCarrierHeader = shift;

	return ( $ccuCarrierHeader->{'carrierId'} == 0
		  && $ccuCarrierHeader->{'axcStartContainer'} == 0
		  && $ccuCarrierHeader->{'axcContainerGroupLength'} == 0
		  && $ccuCarrierHeader->{'bfPeriod'} == 0
		  && $ccuCarrierHeader->{'technology'} == 0
		  && $ccuCarrierHeader->{'fsInfoBf'} == 0
		  && $ccuCarrierHeader->{'fsInfoHf'} == 0
		  && $ccuCarrierHeader->{'noOfAxcContainers'} == 0 );
}

#----------------------------------------------------------------
# Name: checkUlIqData
# Description: Instructs the signal generator to generate a specific
#              signal and calculates the digital effect going out on
#              the CPRI link.
#
# Args: Hash containing:
#         'ratType' [1=LTE, 2=WCDMA(7-bit)] The RAT type of the
#                   carrier.
#         'sigGenPower' [dBm] The signal strength to use.
#         'freq' [kHz] The center frequency of the signal.
#         'bw' [kHz] The bandwidth of the carrier to measure.
#         'rfPort' [0=RfA, 1=RfB] The RF port that has the carrier.
#         'extGain' [dB] The gain contribution between the ARP and the
#                        RU (e.g. from a TMA)
#         'carrierOffset' [<int>] The 0-based offset for this carrier
#                         among the carriers setup in the RUMA.
#
#         LTE only:
#           'reportedGain' [dB] The value reported in
#                               ulGainArpToBbcell from
#                               DC_TR_SETUP_CFM.
#           'subBandWidth' [kHz] (OPTIONAL) The sub band bandwidth, if
#                                the sub band function is used.
#         WCDMA only:
#           'iqDataFormat' Described in 1/155 19-HRB 105 600.
#                          For WCDMA both IQ Data Formats of 7bit and 5bit
#                          can be used.
#                          On 2.5G Cpri, this means:
#                          - IQ Data Format 7 bit -> Axc Slot Size 30 bits.
#                          - IQ Data Format 5 bit -> Axc Slot Size 20 bits.
#
# Example: checkUlIqData( { sigGenPower => -70, freq => 1727400,
#                           bw => 15000, rfPort => 0, ratType => 1,
#                           extGain => 15, carrierOffset => 1,
#                           reportedGain => 134.9, subBandBandWidth => 5000 } );
#          Generates a signal of -70 dBm at 1727.4 MHz for a 15 MHz
#          LTE carrier with subband. There is a TMA with 15 dB gain
#          connected to this port and 'ulGainArpToBbCell' in
#          DC_TR_SETUP_CFM was 134.9 (0x545).
#----------------------------------------------------------------
sub checkUlIqData {
	my $args = shift;

	# Check parameters
	#_checkRequiredArgs($args, ['ratType', 'sigGenPower', 'freq', 'bw', 'rfPort',
	#'extGain', 'carrierOffset']);
	if ( $args->{'ratType'} == 1 )    # LTE
	{

		#_checkRequiredArgs($args, ['reportedGain']);
	} elsif ( $args->{'ratType'} == 3 )    # WCDMA.
	{

		# _checkRequiredArgs($args, ['iqDataFormat']);
	}

	# Convert the RAT type
	my $measurements_ratType;
	my $ulData_ratType;
	if ( $args->{'ratType'} == 1 )         # LTE
	{
		$measurements_ratType = 0;
		$ulData_ratType       = 1;
	} elsif ( $args->{'ratType'} == 3 )    # WCDMA 7-bit OR 5-bit
	{
		$measurements_ratType = 3;
		$ulData_ratType       = 3;
	} elsif ( $args->{'ratType'} == 4 )    # CDMA
	{
		$measurements_ratType = 4;
		$ulData_ratType       = 4;
	}

	# Generate a signal
	#Measurements::changeSettingsSignalGenerator(
	#    { ratType => $measurements_ratType,
	#      port  => $args->{'rfPort'},
	#      freq  => $args->{'freq'},
	#      bw    => $args->{'bw'},
	#      level => $args->{'sigGenPower'} } );

	# Sample the values on the CPRI link and calculate the effect
	if ( $args->{'ratType'} == 1 )    # LTE
	{
		sampleAndCheckUL(
			{
				ratType          => $ulData_ratType,
				sigGenPower      => $args->{'sigGenPower'},
				extGain          => $args->{'extGain'},
				bw               => $args->{'bw'},
				carrierOffset    => $args->{'carrierOffset'},
				reportedGain     => $args->{'reportedGain'},
				subBandBandWidth => $args->{'subBandBandWidth'},    #optional
			}
		);
	} elsif ( $args->{'ratType'} == 3 )    #WCDMA 7-bit OR 5-bit
	{
		sampleAndCheckUL(
			{
				ratType       => $ulData_ratType,
				sigGenPower   => $args->{'sigGenPower'},
				extGain       => $args->{'extGain'},
				carrierOffset => $args->{'carrierOffset'},
				iqDataFormat  => $args->{'iqDataFormat'}
			}
		);
	} elsif ( $args->{'ratType'} == 4 )    # CDMA
	{
		sampleAndCheckUL(
			{
				ratType          => $ulData_ratType,
				sigGenPower      => $args->{'sigGenPower'},
				extGain          => $args->{'extGain'},
				bw               => $args->{'bw'},
				carrierOffset    => $args->{'carrierOffset'},
				reportedGain     => $args->{'reportedGain'},
				subBandBandWidth => $args->{'subBandBandWidth'},    #optional
			}
		);
	}
}

#-#----------------------------------------------------------------
# Name: sampleAndCheckUL
# Description: Record an UL sample with RUMA and check the IQ data
#              against expected signal level. It also checks the
#              number of carriers represented in the IQ data.
#----------------------------------------------------------------
# TODO: Make this function private to be called by checkUlIqData
# only. This requires updating both singlemode and mixedmode
# testcases.
sub sampleAndCheckUL {
	my $args = shift;

	# TODO: Remove default value when function has been made private.
	#_setDefaultArgs($args, {ratType => 1});

	#my $sample;
	#$sample = Functions_Ruma::sampleUl({sampleType => 4,product =>'rul'}) if($args->{'ratType'} == 0);
	#$sample = Functions_Ruma::sampleUl({sampleType => 4,product =>'rul'}) if($args->{'ratType'} == 1);

	# If WCDMA, we need to know which repo. MSR repo only uses ruw, but wcdma uses both ruw and rruw.
	my $repo = "msr";

	#Prints::print_log("############ REPO=$repo ###########\n");

	#if($args->{'ratType'} == 3) {
	#   my $product = ( $repo =~ /wcdma/ ) ? Parameter_handler::get_product() : 'ruw';
	#   $sample = Functions_Ruma::sampleUl({sampleType => 3,product => $product});
	#}

	#$sample = Functions_Ruma::sampleUl({sampleType => 4,product =>'cdma'}) if($args->{'ratType'} == 4);
	my $sampleData = _process_sample( $sample, $args );
	_check_sample( $sampleData, $args );
}

#----------------------------------------------------------------
# Name: _process_sample
# Description: process the bytes to values used inorder determine the digital power
# In the CPRI.
# Following 1533-LPA 108254/1 Rev AC 14.8.2
# Args:
#     'sampleData' - Hash retrieved from Functions_Ruma::sampleUl
#     'args' - Hash of arguments (see checkUlIqData)
# Return:
#   A hash suitable for _check_sample for the used RAT type.
#----------------------------------------------------------------

sub _process_sample {
	my $sampleData    = shift;
	my $args          = shift;
	my $initial_chars = chr( $sampleData->[0] ) . chr( $sampleData->[1] ) . chr( $sampleData->[2] ) . chr( $sampleData->[3] );
	if ( $initial_chars eq ".ccu" ) {
		say("Detected CCU format");
		processUlData($sampleData);
		if (   $args->{ratType} eq 0
			|| $args->{ratType} eq 1
			|| $args->{ratType} eq 4 )
		{

			# LTE or CDMA
			return _process_ccu_sample_lte( $sampleData, $args );
		} elsif ( $args->{ratType} eq 3 ) {    # WCDMA
			if ( $args->{iqDataFormat} eq '7bit30Axc' ) {    # WCDMA 7-bit
				                                             #return _process_sample_wcdma7($sampleData, $args);
				_process_ccu_sample_wcdma7( $sampleData, $args );
			}
		} elsif ( $args->{iqDataFormat} eq '5bit20Axc' ) {    # WCDMA 5-bit
			return _process_sample_wcdma5( $sampleData, $args );
		}
	}
}

sub _process_ccu_sample_wcdma7 {
	my $sampleData = shift;
	my $args       = shift;

	say("\n====================================================");
	say("_process_ccu_sample_wcdma7: Processing CCU UL data (wcdma7) received from RUMA");

	#Extract the header information
	processUlData($sampleData);
	my @iqVal             = ();
	my @agcVal            = ();
	my $AxcContainerStart = 128 + $ulDataHeader{'noOfCarriers'} * $ulDataHeader{'carrierHeaderSize'};

	#print Dumper \%ulDataHeader;
	my $AxcContainerEnd = $AxcContainerStart + $ulDataHeader{'carrierHeaders'}[0]{'noOfAxcContainers'} * 4;

	#_printHex ($sampleData,$AxcContainerStart ,($AxcContainerEnd-$AxcContainerStart));
	for ( my $idx = $AxcContainerStart ; $idx < $AxcContainerEnd ; $idx += 4 ) {
		my $Q1 = $sampleData->[ $idx + 1 ] & 0x7f;
		my $I1 = $sampleData->[ $idx + 0 ] & 0x7f;
		my $Q2 = $sampleData->[ $idx + 3 ] & 0x7f;
		my $I2 = $sampleData->[ $idx + 2 ] & 0x7f;

		#say "[$idx]$sampleData->[$idx+0]:$sampleData->[$idx+1]:$sampleData->[$idx+2]:$sampleData->[$idx+3]";
		my $cbit = $sampleData->[ $idx + 3 ] & 0x80;
		my $AGC  = $sampleData->[ $idx + 2 ] & 0x80;

		#say "I1:$I1,Q1:$Q1,I2:$I2,Q2:$Q2,cbit:$cbit,AGC:$AGC";
		#say "cbit:$cbit";
		my $decodedI1 = _decode_IQ_value( $args, $I1 );
		my $decodedQ1 = _decode_IQ_value( $args, $Q1 );
		my $decodedI2 = _decode_IQ_value( $args, $I2 );
		my $decodedQ2 = _decode_IQ_value( $args, $Q2 );
		push @iqVal, $decodedI2, $decodedQ1, $decodedI2, $decodedQ2;
		push @agcVal, $AGC;
	}
	my %returned_data_ref = (
		IQ_data  => $iqVal,
		AGC_data => $agcVal
	);
	return \%returned_data_ref;
}

sub _process_sample_lte {
	my $ulData = shift;
	my $args   = shift;

	#_checkRequiredArgs($args, ['bw']);
	#_setDefaultArgs($args, { carrierOffset => 0 });

	say("\n====================================================");
	say("Processing UL data (LTE) received from RUMA");

	#my $headerData = _process_sample_header($ulData);

	# Print first basic frame (64 bytes)
	#_printHex($ulData, 160, 512*4);

	# After the heading comes the IQ data according to
	# 1533-LPA 108254/1 Rev AC 14.8.2

	my @iqVal = ();
	my @iqExp = ();
	my $index = 160;
	while ( defined( $ulData->[ $index + 3 ] ) ) {
		my $byte0 = $ulData->[ $index + 0 ] & 0x0F;
		my $byte1 = $ulData->[ $index + 1 ] & 0xFF;
		my $byte2 = $ulData->[ $index + 2 ] & 0x0F;
		my $byte3 = $ulData->[ $index + 3 ] & 0xFF;
		my $value = ( $byte1 << 8 ) | $byte0;         # second byte contains the four most significant bits
		my $exp   = $byte3 & 0xF0;

		my $decodedValue = _decode_IQ_value( $args, $value );
		push @iqVal, $decodedValue;
		push @iqExp, $exp;

		$index = $index + 4;
	}

	my ( $IQ_data, $exp_data ) = _IQ_Vector_lte(
		{
			Data              => \@iqVal,
			exp_vector        => \@iqExp,
			samples_per_frame => _getSamplesPerFrame( $args->{ratType}, $args->{bw} ),
			carrierOffset     => $args->{carrierOffset}
		}
	);

	my %returned_data_ref = (
		IQ_data  => $IQ_data,
		exp_data => $exp_data
	);
	return \%returned_data_ref;
}

sub _process_ccu_sample_lte {
	my $ulData = shift;
	my $args   = shift;

	say("\n====================================================");
	say("_process_ccu_sample_lte: Processing CCU UL data (lte) received from RUMA");

	my @iqVal             = ();
	my @iqExp             = ();
	my $AxcContainerStartIdx = 128 + $ulDataHeader{'noOfCarriers'} * $ulDataHeader{'carrierHeaderSize'};
	my $AxcContainerEndIdx   = $AxcContainerStartIdx + $ulDataHeader{'carrierHeaders'}[0]{'noOfAxcContainers'}*4;
	say "Start:$AxcContainerStartIdx End:$AxcContainerEndIdx";
	for ( my $idx = $AxcContainerStartIdx ; $idx < $AxcContainerEndIdx ; $idx += 4 ) {
		my $byte0    = $ulData->[ $idx + 0 ];
		my $byte1    = $ulData->[ $idx + 1 ];
		my $byte2    = $ulData->[ $idx + 2 ];
		my $byte3    = $ulData->[ $idx + 3 ];
		my $I        = $byte0 | ( ( $byte1 & 0x0F ) << 8 );
		my $Q        = $byte2 | ( ( $byte3 & 0x0F ) << 8 );
		my $exp      = ( $byte1 & 0xF0 >> 4 );
		my $decodedI = _decode_IQ_value( $args, $I );
		my $decodedQ = _decode_IQ_value( $args, $Q );
		push @iqVal, $decodedI, $decodedQ;
		push @iqExp, $exp,      $exp;
	}

	my %returned_data_ref = (
		IQ_data  => \@iqVal,
		exp_data => \@iqExp
	);
	return \%returned_data_ref;
}

#----------------------------------------------------------------
# Name: _decode_IQ_value
# Description: Decodes the bit value (as received on the link) to a
#              numerical value to use in calculations. Only the bits
#              belonging to the I/Q value are expected, so i.e. a
#              5-bit value needs to be between 00000000 and 00011111.
#----------------------------------------------------------------
sub _decode_IQ_value {
	my $args  = shift;
	my $value = shift;

	if (   $args->{ratType} == 0
		|| $args->{ratType} == 1
		|| $args->{ratType} == 4 )
	{    # LTE or CDMA
		    # If the first bit (of the 12 bits) is set, then we have a
		    # negative number according to 1/155 19-HRB 105 600, chapter
		    # 3.3.2.1
		if ( $value & 0x800 ) {
			return -1 - ( ( ~$value ) & 0xFFF );
		} else {
			return $value;
		}
	} elsif ( $args->{ratType} == 3 ) {    # WCDMA
		if ( $args->{iqDataFormat} eq '7bit30Axc' ) {    # WCDMA 7-bit
			$value = $value & 0x7f;
			if ( $value & 0x40 ) {

				# first bit of 7 is set, so we have a negative number -
				# flip the 6 remaining bits
				return -0.125 - ( ( ~$value ) & 0x3f ) * 0.25;
			} else {
				return 0.125 + ( $value & 0x3f ) * 0.25;
			}
		} elsif ( $args->{iqDataFormat} eq '5bit20Axc' ) {    # WCDMA 5-bit
			$value = $value & 0x1f;

			if ( $value & 0x10 ) {

				# first bit of 5 is set, so we have a negative number -
				return -0.5 - ( ( ~$value ) & 0xf );
			} else {
				return 0.5 + ( $value & 0xf );
			}
		}
	}
}

#----------------------------------------------------------------
# Called by _process_sample_lte to retrieve I, Q and Exp values.
#----------------------------------------------------------------
sub _IQ_Vector_lte {
	my $args            = shift;
	my $IQ              = $args->{Data};
	my $IQexp           = $args->{exp_vector};
	my $samplesPerFrame = $args->{samples_per_frame};
	my @exp_Carr1;
	my @IQ_Carr1;
	my $carrierOffset = $args->{carrierOffset};

	# Take the carrierOffset into account and pick out the correct IQ
	# values within the basic frame (total of 16 samples in a BF) if we
	# have several carriers set up.
	for ( my $j = $carrierOffset * $samplesPerFrame * 2 ; $j < scalar(@$IQ) ; $j += 16 ) {
		if ( defined( $IQ->[ $j + 15 ] ) and defined( $IQexp->[ $j + 15 ] ) ) {
			for ( my $i = 0 ; $i < $samplesPerFrame ; $i++ ) {
				push @exp_Carr1, $IQexp->[ $j + $i * 2 ];
				push @IQ_Carr1,  $IQ->[ $j + $i * 2 ];
				push @exp_Carr1, $IQexp->[ $j + $i * 2 + 1 ];
				push @IQ_Carr1,  $IQ->[ $j + $i * 2 + 1 ];
			}
		}
	}

	return ( \@IQ_Carr1, \@exp_Carr1 );

}

#----------------------------------------------------------------
# Name: _getSamplesPerFrame
# Description: Calculates how many samples are used within a CPRI
#              frame for a carrier of a given bandwidth.
# Args:
#    bw: The bandwidth in KHz
# Returns:
#    The number of samples.
#----------------------------------------------------------------
sub _getSamplesPerFrame {    #TODO: This function also exists in Functions_Ruma
	my $techn = shift;
	my $bw    = shift;
	if ( $techn == 3 ) {
		return 1;
	} else {
		my %samples_per_frame_hash = (
			200   => 1,
			1230  => 1,
			1400  => 1,
			3000  => 1,
			5000  => 2,      #7.68
			10000 => 4,      #15.36
			15000 => 6,      #23.04
			20000 => 8,      #30.72
		);
		return $samples_per_frame_hash{$bw};
	}
}

#----------------------------------------------------------------
# Name: _check_sample
# Description: calls sub functions depending on RAT type
#----------------------------------------------------------------
sub _check_sample {
	my $sampleData = shift;
	my $args       = shift;

	#_checkRequiredArgs($args, ['ratType']);

	if (   $args->{ratType} eq 0
		|| $args->{ratType} eq 1
		|| $args->{ratType} eq 4 )
	{

		#LTE or CDMA
		_check_sample_lte( $sampleData, $args );
	} elsif ( $args->{ratType} eq 3 ) {

		#WCDMA 7-bit OR 5-bit.
		_check_sample_wcdma( $sampleData, $args );
	}
}

#----------------------------------------------------------------
# Name: _check_sample_lte
# Description: estimate The power on CPRI for LTE.
# Args:
#   'sampleData': Struct containing
#      'IQ_data' The an array ref with IQ_data
#      'exp_data' An array ref with exp data for LTE
#   'args' - Hash containing arguments from checkUlIqData
#----------------------------------------------------------------
sub _check_sample_lte {
	my $sampleData = shift;
	my $args       = shift;
	my $IQ_data      = $sampleData->{IQ_data};
	my $exp_data     = $sampleData->{exp_data};
	my $bw           = $args->{'bw'};
	my $sigGenPower  = $args->{sigGenPower};
	my $extGain      = $args->{extGain};
	my $reportedGain = $args->{reportedGain};     # ulGainArpToBbcell

	my $numSubBandCarriers = 1;
	if ( defined( $args->{'subBandBandWidth'} ) ) {
		my $subBandBW = $args->{'subBandBandWidth'};
		$numSubBandCarriers = int( ( $bw - 1 ) / $subBandBW ) + 1;
	}

	my $nr_of_IQdata = scalar(@$IQ_data);
	my $IQsquare     = 0;
	my $Nr           = 0;
	for ( my $index = 0 ; $index < $nr_of_IQdata - 1 ; $index += 2 ) {
		my $I    = $IQ_data->[$index];
		my $Iexp = $exp_data->[$index];
		my $Q    = $IQ_data->[ $index + 1 ];
		my $Qexp = $exp_data->[ $index + 1 ];

		# Equation from FS LTE 4.10.1.2
		my $IQsquareExtra = ( $I * ( 2**$Iexp ) )**2 + ( $Q * ( 2**$Qexp ) )**2;
		$IQsquare = $IQsquareExtra + $IQsquare;		
		$Nr++;
	}
	my $power = 0;
	$power = 10 * log( $numSubBandCarriers * $IQsquare / $Nr ) / log(10)
	  if ( $numSubBandCarriers * $IQsquare );
	my $power_str = sprintf( '%.2f', $power );
	say("############Power=$power_str [dBm] ###########\n");
	say("############SigPower=$sigGenPower [dBm] ###########\n");
	my $tot_gain = $power - $sigGenPower;
	my $tot_gain_str = sprintf( '%.2f', $tot_gain );
	say("############Total Gain=$tot_gain_str [dB] ###########\n");
	say("############Reported UL Gain=$reportedGain [dB] ###########\n");
	say("############Expected external gain=$extGain [dB] ###########\n");
	my $diff = int( abs( $tot_gain - $reportedGain + $extGain ) * 100 ) / 100;

	if ( $diff < 1.7 ) {
		my $diff_str = sprintf( '%.2f', $diff );
		say("#####################PASS $diff_str is less than 1.7 [dB]\n");
	} else {
		say("$diff is more than 1.7 [dB]\n");
	}
}

#----------------------------------------------------------------
# Name: _check_sample_wcdma
# Description: estimate The power on CPRI for WCDMA 7-bit OR WCDMA 5-bit
# Args:
#   'sampleData' - Hash containing:
#      'IQ_data' The an array ref with IQ_data
#      'AGC_data' An array ref with AGC data
#   'args' - Hash containing arguments from checkUlIqData
#----------------------------------------------------------------
sub _check_sample_wcdma {
	my $sampleData = shift;
	my $args       = shift;

	#_checkRequiredArgs($sampleData, ['IQ_data', 'AGC_data']);
	#_checkRequiredArgs($args, ['iqDataFormat', 'sigGenPower', 'extGain', 'carrierOffset']);

	my $IQ_data       = $sampleData->{IQ_data};
	my $AGC_data      = $sampleData->{AGC_data};
	my $sigGenPower   = $args->{sigGenPower};
	my $CarrierOffset = $args->{carrierOffset};

	my $totalGain = 17;

	my $k_ubp_dbm = 100;

	my $nr_of_IQdata = scalar(@$IQ_data);
	my $Nr           = 0;
	my $IQsum        = 0;
	my $alfa         = 0;
	say("############ Carrier $CarrierOffset ###########\n");
	for ( my $index = 0 ; $index + 3 < $nr_of_IQdata ; $index += 4 ) {
		my $I1  = $IQ_data->[ $index + 0 ];
		my $Q1  = $IQ_data->[ $index + 1 ];
		my $I2  = $IQ_data->[ $index + 2 ];
		my $Q2  = $IQ_data->[ $index + 3 ];
		my $AGC = $AGC_data->[$index];        # Only looks at the first AGC value, but all four should be equal
		my $S   = $AGC & 0x03;                #The last 2 bits in AGC is the S value
		my $B   = ( $AGC >> 2 ) & 0x0f;       #The first 4 bits (out of 6) in AGC is the B value
		$alfa = ( 2**$B ) * ( 1 + $S / 4 );
		$IQsum = $I1**2 + $Q1**2 + $I2**2 + $Q2**2 + $IQsum;
		$Nr += 2;
	}
	my $P_gamma = 10 * log( $IQsum / $Nr ) / log(10) + 20 * log( ( 2**15 ) / $alfa ) / log(10);
	my $diff = int( abs( $P_gamma - ( $sigGenPower + $k_ubp_dbm ) ) * 100 ) / 100;
	say("##################### The estimated power in CPRI: P_gamma = $P_gamma [dBm]\n");
	say("##################### K_UBP_DBM = $k_ubp_dbm [dBm]\n");
	say("##################### P_ANT_REF_RX is the power from the signalgenerator, which is $sigGenPower [dBm] \n");
	say("##################### (P_gamma + k_ubp_dbm - P_ANT_REF_RX) is the diff value\n");
	say("##################### (P_gamma - (P_ANT_REF_RX + k_ubp_dbm)) is the diff value\n");

	if ( $diff < 1.7 ) {
		my $diff_str = sprintf( '%.2f', $diff );
		say("#####################PASS Diff $diff_str is less than 1.7 [dB]");
	} else {
		say("ERROR: Diff $diff is more than 1.7 [dB]");
	}
}
