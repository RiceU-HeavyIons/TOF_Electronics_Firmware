trigger_counter_15bit_inst : trigger_counter_15bit PORT MAP (
		clock	 => clock_sig,
		cnt_en	 => cnt_en_sig,
		aclr	 => aclr_sig,
		q	 => q_sig,
		cout	 => cout_sig
	);
