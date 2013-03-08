reg8_en_inst : reg8_en PORT MAP (
		clock	 => clock_sig,
		enable	 => enable_sig,
		sclr	 => sclr_sig,
		data	 => data_sig,
		q	 => q_sig
	);
