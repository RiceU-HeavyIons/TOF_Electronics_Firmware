trigger_counter_12bit_inst : trigger_counter_12bit PORT MAP (
		clock	 => clock_sig,
		cnt_en	 => cnt_en_sig,
		aclr	 => aclr_sig,
		q	 => q_sig,
		cout	 => cout_sig
	);
