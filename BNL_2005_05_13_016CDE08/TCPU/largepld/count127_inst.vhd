count127_inst : count127 PORT MAP (
		clock	 => clock_sig,
		cnt_en	 => cnt_en_sig,
		aclr	 => aclr_sig,
		q	 => q_sig,
		cout	 => cout_sig
	);
