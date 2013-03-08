timeout_ctr_8bit_inst : timeout_ctr_8bit PORT MAP (
		clock	 => clock_sig,
		cnt_en	 => cnt_en_sig,
		sclr	 => sclr_sig,
		q	 => q_sig,
		cout	 => cout_sig
	);
