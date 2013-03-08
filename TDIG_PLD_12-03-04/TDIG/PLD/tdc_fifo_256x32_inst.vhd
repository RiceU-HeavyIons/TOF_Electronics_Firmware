tdc_fifo_256x32_inst : tdc_fifo_256x32 PORT MAP (
		data	 => data_sig,
		wrreq	 => wrreq_sig,
		rdreq	 => rdreq_sig,
		clock	 => clock_sig,
		aclr	 => aclr_sig,
		q	 => q_sig,
		empty	 => empty_sig
	);
